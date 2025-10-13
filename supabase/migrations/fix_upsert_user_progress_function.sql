-- Fix upsert_user_progress function to remove reference to accepted_nutrition_suggestions
-- This resolves the error: record "progress_data" has no field "accepted_nutrition_suggestions"

-- Drop the existing function that has the incorrect signature
DROP FUNCTION IF EXISTS upsert_user_progress(UUID, VARCHAR(255), TEXT);
DROP FUNCTION IF EXISTS upsert_user_progress(UUID);

-- Recreate the function without the accepted_nutrition_suggestions field
CREATE OR REPLACE FUNCTION upsert_user_progress(p_user_id UUID, p_user_name VARCHAR(255) DEFAULT NULL, p_user_profile_image TEXT DEFAULT '')
RETURNS VOID AS $$
DECLARE
    progress_data RECORD;
BEGIN
    -- Calculate progress data using the current calculate_user_progress function
    SELECT * INTO progress_data FROM calculate_user_progress(p_user_id);
    
    -- Upsert user progress without the accepted_nutrition_suggestions field
    INSERT INTO user_progress (
        user_id,
        user_name,
        user_profile_image,
        weekly_completed_habits,
        suggested_habits,
        pending_activities,
        new_habits,
        weekly_progress_percentage,
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
        motivational_message = EXCLUDED.motivational_message,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION upsert_user_progress(UUID, VARCHAR(255), TEXT) TO anon;
GRANT EXECUTE ON FUNCTION upsert_user_progress(UUID, VARCHAR(255), TEXT) TO authenticated;

-- Add comment
COMMENT ON FUNCTION upsert_user_progress(UUID, VARCHAR(255), TEXT) IS 'Upserts user progress data without nutrition suggestions field to match current calculate_user_progress function signature';