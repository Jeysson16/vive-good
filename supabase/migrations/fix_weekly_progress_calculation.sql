-- Fix weekly progress calculation to properly calculate weekly completion rate
-- This corrects the confusion between daily and weekly progress

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
            -- Check if completed TODAY (for daily progress)
            CASE WHEN EXISTS(
                SELECT 1 FROM user_habit_logs uhl 
                WHERE uhl.user_habit_id = uh.id 
                AND uhl.status = 'completed'
                AND DATE(uhl.completed_at) = CURRENT_DATE
            ) THEN 1 ELSE 0 END as completed_today,
            -- Check if completed this week (for weekly progress)
            CASE WHEN EXISTS(
                SELECT 1 FROM user_habit_logs uhl 
                WHERE uhl.user_habit_id = uh.id 
                AND uhl.status = 'completed'
                AND uhl.completed_at >= DATE_TRUNC('week', CURRENT_DATE)
                AND uhl.completed_at < DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '7 days'
            ) THEN 1 ELSE 0 END as completed_this_week,
            -- Check if it's pending (active but not completed today)
            CASE WHEN uh.is_active = true AND NOT EXISTS(
                SELECT 1 FROM user_habit_logs uhl 
                WHERE uhl.user_habit_id = uh.id 
                AND uhl.status = 'completed'
                AND DATE(uhl.completed_at) = CURRENT_DATE
            ) THEN 1 ELSE 0 END as is_pending
        FROM public.user_habits uh
        WHERE uh.user_id = p_user_id AND uh.is_active = true
    ),
    weekly_completion_stats AS (
        SELECT 
            COUNT(*) as total_active_habits,
            -- Count total completions this week (not unique habits)
            COALESCE((
                SELECT COUNT(*) 
                FROM user_habit_logs uhl 
                INNER JOIN user_habits uh ON uh.id = uhl.user_habit_id
                WHERE uh.user_id = p_user_id 
                AND uh.is_active = true
                AND uhl.status = 'completed'
                AND uhl.completed_at >= DATE_TRUNC('week', CURRENT_DATE)
                AND uhl.completed_at < DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '7 days'
            ), 0) as total_weekly_completions
        FROM habit_stats hs
    )
    SELECT 
        -- Total completions this week (can be more than number of habits)
        wcs.total_weekly_completions::INTEGER as weekly_completed_habits,
        -- Total active habits (suggested habits)
        wcs.total_active_habits::INTEGER as suggested_habits,
        -- Pending activities today
        COALESCE(SUM(hs.is_pending)::INTEGER, 0) as pending_activities,
        -- New habits created this week
        COALESCE(COUNT(CASE WHEN hs.created_at >= NOW() - INTERVAL '7 days' THEN 1 END)::INTEGER, 0) as new_habits,
        -- Weekly progress: total completions / (total habits * 7 days)
        CASE 
            WHEN wcs.total_active_habits > 0 THEN 
                LEAST(100.0, GREATEST(0.0, 
                    ROUND((wcs.total_weekly_completions::DECIMAL / (wcs.total_active_habits::DECIMAL * 7)) * 100, 2)
                ))
            ELSE 0.0
        END as weekly_progress_percentage
    FROM habit_stats hs
    CROSS JOIN weekly_completion_stats wcs
    GROUP BY wcs.total_active_habits, wcs.total_weekly_completions;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION calculate_user_progress(UUID) TO anon;
GRANT EXECUTE ON FUNCTION calculate_user_progress(UUID) TO authenticated;

-- Add comment
COMMENT ON FUNCTION calculate_user_progress(UUID) IS 'Calculates user progress metrics with proper weekly completion rate (total completions / (habits * 7 days))';