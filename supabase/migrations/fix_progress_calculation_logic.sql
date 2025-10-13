-- Fix progress calculation logic to show accurate daily and weekly progress
-- This migration corrects the calculation to be based on today's completion vs total habits

-- Drop existing function to recreate with correct logic
DROP FUNCTION IF EXISTS calculate_user_progress(UUID);

-- Create improved function to calculate user progress with accurate daily/weekly logic
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
            -- Check if completed TODAY (not this week)
            CASE WHEN EXISTS(
                SELECT 1 FROM user_habit_logs uhl 
                WHERE uhl.user_habit_id = uh.id 
                AND uhl.status = 'completed'
                AND DATE(uhl.completed_at) = CURRENT_DATE
            ) THEN 1 ELSE 0 END as completed_today,
            -- Check if completed this week for weekly stats
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
        -- Use today's completed habits for more accurate representation
        COALESCE(SUM(hs.completed_today)::INTEGER, 0) as weekly_completed_habits,
        COALESCE(COUNT(*)::INTEGER, 0) as suggested_habits, -- Total active habits
        COALESCE(SUM(hs.is_pending)::INTEGER, 0) as pending_activities,
        COALESCE(COUNT(CASE WHEN hs.created_at >= NOW() - INTERVAL '7 days' THEN 1 END)::INTEGER, 0) as new_habits,
        -- Calculate percentage based on TODAY's completion vs total active habits
        CASE 
            WHEN COUNT(*) > 0 THEN 
                ROUND((SUM(hs.completed_today)::DECIMAL / COUNT(*)::DECIMAL) * 100, 2)
            ELSE 0.0
        END as weekly_progress_percentage,
        COALESCE(SUM(hs.is_nutrition)::INTEGER, 0) as accepted_nutrition_suggestions
    FROM habit_stats hs;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update the streak calculation function to be more accurate
CREATE OR REPLACE FUNCTION calculate_user_streak(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    current_streak INTEGER := 0;
    check_date DATE;
    has_completion BOOLEAN;
BEGIN
    -- Start from yesterday (not today) to avoid counting incomplete today
    check_date := CURRENT_DATE - INTERVAL '1 day';
    
    -- Check each day going backwards until we find a day without completions
    LOOP
        -- Check if user completed at least one habit on this date
        SELECT EXISTS(
            SELECT 1 
            FROM user_habit_logs uhl
            JOIN user_habits uh ON uh.id = uhl.user_habit_id
            WHERE uh.user_id = p_user_id 
            AND uhl.status = 'completed'
            AND DATE(uhl.completed_at) = check_date
        ) INTO has_completion;
        
        -- If no completion found, break the streak
        IF NOT has_completion THEN
            EXIT;
        END IF;
        
        -- Increment streak and check previous day
        current_streak := current_streak + 1;
        check_date := check_date - INTERVAL '1 day';

        -- Limit to reasonable streak length (avoid infinite loops)
        IF current_streak >= 365 THEN
            EXIT;
        END IF;
    END LOOP;
    
    -- If today has completions, add 1 to the streak
    SELECT EXISTS(
        SELECT 1 
        FROM user_habit_logs uhl
        JOIN user_habits uh ON uh.id = uhl.user_habit_id
        WHERE uh.user_id = p_user_id 
        AND uhl.status = 'completed'
        AND DATE(uhl.completed_at) = CURRENT_DATE
    ) INTO has_completion;
    
    IF has_completion THEN
        current_streak := current_streak + 1;
    END IF;
    
    RETURN current_streak;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION calculate_user_progress(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_user_streak(UUID) TO authenticated;