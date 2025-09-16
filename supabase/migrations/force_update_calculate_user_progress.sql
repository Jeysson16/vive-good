-- Force update calculate_user_progress function by dropping and recreating it
-- This ensures the old version with incorrect column references is completely removed

-- Drop the existing function if it exists
DROP FUNCTION IF EXISTS calculate_user_progress(UUID);

-- Recreate the function with correct column references
CREATE OR REPLACE FUNCTION calculate_user_progress(p_user_id UUID)
RETURNS TABLE (
    weekly_completed_habits INTEGER,
    suggested_habits INTEGER,
    pending_activities INTEGER,
    new_habits INTEGER,
    weekly_progress_percentage DECIMAL(5,2)
) AS $$
BEGIN
    RETURN QUERY
    WITH habit_stats AS (
        SELECT 
            uh.id as user_habit_id,
            uh.created_at,
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
            ) THEN 1 ELSE 0 END as is_pending
        FROM public.user_habits uh
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
        END as weekly_progress_percentage
    FROM habit_stats hs;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION calculate_user_progress(UUID) TO anon;
GRANT EXECUTE ON FUNCTION calculate_user_progress(UUID) TO authenticated;

-- Add comment
COMMENT ON FUNCTION calculate_user_progress(UUID) IS 'Calculates user progress metrics based on user_habits and user_habit_logs tables';