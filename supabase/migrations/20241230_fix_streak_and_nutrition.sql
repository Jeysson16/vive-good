-- Fix streak calculation and nutrition suggestions
-- This migration drops existing functions and recreates them with proper signatures

-- Drop existing functions to avoid conflicts
DROP FUNCTION IF EXISTS calculate_user_progress(UUID);
DROP FUNCTION IF EXISTS upsert_user_progress(UUID, VARCHAR(255), TEXT);
DROP FUNCTION IF EXISTS upsert_user_progress(UUID);
DROP FUNCTION IF EXISTS calculate_user_streak(UUID);

-- Create function to calculate user streak (consecutive days with at least one completed habit)
CREATE OR REPLACE FUNCTION calculate_user_streak(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    current_streak INTEGER := 0;
    check_date DATE := CURRENT_DATE;
    has_activity BOOLEAN;
BEGIN
    -- Start from today and go backwards
    LOOP
        -- Check if user has any completed habits on this date
        SELECT EXISTS(
            SELECT 1 
            FROM user_habit_logs uhl
            JOIN user_habits uh ON uh.id = uhl.user_habit_id
            WHERE uh.user_id = p_user_id 
            AND uhl.status = 'completed'
            AND DATE(uhl.completed_at) = check_date
        ) INTO has_activity;
        
        -- If no activity on this date, break the streak
        IF NOT has_activity THEN
            -- If it's today and no activity, streak is 0
            IF check_date = CURRENT_DATE THEN
                current_streak := 0;
            END IF;
            EXIT;
        END IF;
        
        -- Increment streak and check previous day
        current_streak := current_streak + 1;
        check_date := check_date - INTERVAL '1 day';
        
        -- Prevent infinite loop (max 365 days)
        IF current_streak >= 365 THEN
            EXIT;
        END IF;
    END LOOP;
    
    RETURN current_streak;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update calculate_user_progress function to include proper nutrition suggestions calculation
CREATE OR REPLACE FUNCTION calculate_user_progress(p_user_id UUID)
RETURNS TABLE (
    weekly_completed_habits INTEGER,
    suggested_habits INTEGER,
    pending_activities INTEGER,
    new_habits INTEGER,
    weekly_progress_percentage DECIMAL(5,2),
    accepted_nutrition_suggestions INTEGER
) AS $$
BEGIN
    RETURN QUERY
    WITH habit_stats AS (
        SELECT 
            uh.id as user_habit_id,
            uh.created_at,
            h.category_id,
            -- Check if completed this week based on logs
            CASE WHEN EXISTS(
                SELECT 1 FROM user_habit_logs uhl 
                WHERE uhl.user_habit_id = uh.id 
                AND uhl.status = 'completed'
                AND uhl.completed_at >= NOW() - INTERVAL '7 days'
            ) THEN 1 ELSE 0 END as completed_this_week,
            -- Check if it's a suggested habit (public habits)
            CASE WHEN uh.is_public = true THEN 1 ELSE 0 END as is_suggested,
            -- Check if it's pending (active but not completed today)
            CASE WHEN uh.is_active = true AND NOT EXISTS(
                SELECT 1 FROM user_habit_logs uhl 
                WHERE uhl.user_habit_id = uh.id 
                AND uhl.status = 'completed'
                AND DATE(uhl.completed_at) = CURRENT_DATE
            ) THEN 1 ELSE 0 END as is_pending,
            -- Check if it's a nutrition habit (category 'Alimentación' or 'Nutrición')
            CASE WHEN EXISTS(
                SELECT 1 FROM categories c 
                WHERE c.id = h.category_id 
                AND (LOWER(c.name) LIKE '%alimentaci%' OR LOWER(c.name) LIKE '%nutrici%' OR LOWER(c.name) LIKE '%comida%')
            ) THEN 1 ELSE 0 END as is_nutrition
        FROM public.user_habits uh
        JOIN public.habits h ON h.id = uh.habit_id
        WHERE uh.user_id = p_user_id AND uh.is_active = true
    )
    SELECT 
        COALESCE(SUM(hs.completed_this_week)::INTEGER, 0) as weekly_completed_habits,
        COALESCE(SUM(hs.is_suggested)::INTEGER, 0) as suggested_habits,
        COALESCE(SUM(hs.is_pending)::INTEGER, 0) as pending_activities,
        COALESCE(COUNT(CASE WHEN hs.created_at >= NOW() - INTERVAL '7 days' THEN 1 END)::INTEGER, 0) as new_habits,
        CASE 
            WHEN COUNT(*) > 0 THEN 
                ROUND((SUM(hs.completed_this_week)::DECIMAL / COUNT(*)::DECIMAL) * 100, 2)
            ELSE 0.0
        END as weekly_progress_percentage,
        COALESCE(SUM(hs.is_nutrition)::INTEGER, 0) as accepted_nutrition_suggestions
    FROM habit_stats hs;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update upsert_user_progress function to use the new nutrition calculation
CREATE OR REPLACE FUNCTION upsert_user_progress(p_user_id UUID, p_user_name VARCHAR(255) DEFAULT NULL, p_user_profile_image TEXT DEFAULT '')
RETURNS VOID AS $$
DECLARE
    progress_data RECORD;
BEGIN
    -- Calculate progress data
    SELECT * INTO progress_data FROM calculate_user_progress(p_user_id);
    
    -- Upsert user progress
    INSERT INTO public.user_progress (
        user_id,
        user_name,
        user_profile_image,
        weekly_completed_habits,
        suggested_habits,
        pending_activities,
        new_habits,
        weekly_progress_percentage,
        accepted_nutrition_suggestions,
        motivational_message
    ) VALUES (
        p_user_id,
        COALESCE(p_user_name, 'Usuario'),
        COALESCE(p_user_profile_image, ''),
        progress_data.weekly_completed_habits,
        progress_data.suggested_habits,
        progress_data.pending_activities,
        progress_data.new_habits,
        progress_data.weekly_progress_percentage,
        progress_data.accepted_nutrition_suggestions,
        CASE 
            WHEN progress_data.weekly_progress_percentage >= 80 THEN '¡Excelente progreso! Sigue así.'
            WHEN progress_data.weekly_progress_percentage >= 50 THEN '¡Buen trabajo! Estás en el camino correcto.'
            ELSE '¡Sigue adelante! Cada paso cuenta.'
        END
    )
    ON CONFLICT (user_id) DO UPDATE SET
        user_name = EXCLUDED.user_name,
        user_profile_image = EXCLUDED.user_profile_image,
        weekly_completed_habits = EXCLUDED.weekly_completed_habits,
        suggested_habits = EXCLUDED.suggested_habits,
        pending_activities = EXCLUDED.pending_activities,
        new_habits = EXCLUDED.new_habits,
        weekly_progress_percentage = EXCLUDED.weekly_progress_percentage,
        accepted_nutrition_suggestions = EXCLUDED.accepted_nutrition_suggestions,
        motivational_message = EXCLUDED.motivational_message,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions for the new streak function
GRANT EXECUTE ON FUNCTION calculate_user_streak(UUID) TO anon;
GRANT EXECUTE ON FUNCTION calculate_user_streak(UUID) TO authenticated;

-- Grant permissions for updated functions
GRANT EXECUTE ON FUNCTION calculate_user_progress(UUID) TO anon;
GRANT EXECUTE ON FUNCTION calculate_user_progress(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION upsert_user_progress(UUID, VARCHAR(255), TEXT) TO anon;
GRANT EXECUTE ON FUNCTION upsert_user_progress(UUID, VARCHAR(255), TEXT) TO authenticated;

-- Add comments
COMMENT ON FUNCTION calculate_user_streak(UUID) IS 'Calculates consecutive days with at least one completed habit';
COMMENT ON FUNCTION calculate_user_progress(UUID) IS 'Calculates user progress metrics including proper nutrition suggestions count';
COMMENT ON FUNCTION upsert_user_progress(UUID, VARCHAR(255), TEXT) IS 'Upserts user progress data with corrected nutrition suggestions';