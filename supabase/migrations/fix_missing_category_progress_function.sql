-- Recrear la función get_category_progress_metrics que fue eliminada por error

CREATE OR REPLACE FUNCTION get_category_progress_metrics(p_user_id UUID, p_start_date DATE DEFAULT NULL, p_end_date DATE DEFAULT NULL)
RETURNS TABLE (
    category_name TEXT,
    total_habits INTEGER,
    completed_habits INTEGER,
    completion_rate DECIMAL,
    category_color TEXT,
    category_icon TEXT
) AS $$
DECLARE
    v_start_date DATE;
    v_end_date DATE;
BEGIN
    v_start_date := COALESCE(p_start_date, CURRENT_DATE - INTERVAL '30 days');
    v_end_date := COALESCE(p_end_date, CURRENT_DATE);
    
    RETURN QUERY
    SELECT 
        c.name as category_name,
        COUNT(DISTINCT uh.id)::INTEGER as total_habits,
        COUNT(DISTINCT CASE WHEN uhl.status = 'completed' THEN uh.id END)::INTEGER as completed_habits,
        CASE 
            WHEN COUNT(DISTINCT uh.id) > 0 THEN 
                ROUND((COUNT(DISTINCT CASE WHEN uhl.status = 'completed' THEN uh.id END)::DECIMAL / COUNT(DISTINCT uh.id)) * 100, 1)
            ELSE 0 
        END as completion_rate,
        c.color as category_color,
        c.icon as category_icon
    FROM categories c
    JOIN habits h ON c.id = h.category_id
    JOIN user_habits uh ON h.id = uh.habit_id
    LEFT JOIN user_habit_logs uhl ON uh.id = uhl.user_habit_id 
        AND uhl.completed_at::date BETWEEN v_start_date AND v_end_date
        AND uhl.status = 'completed'
    WHERE uh.user_id = p_user_id
    AND uh.is_active = true
    GROUP BY c.id, c.name, c.color, c.icon
    HAVING COUNT(DISTINCT uh.id) > 0
    ORDER BY completion_rate DESC, total_habits DESC;
    
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_category_progress_metrics(UUID, DATE, DATE) TO anon;
GRANT EXECUTE ON FUNCTION get_category_progress_metrics(UUID, DATE, DATE) TO authenticated;