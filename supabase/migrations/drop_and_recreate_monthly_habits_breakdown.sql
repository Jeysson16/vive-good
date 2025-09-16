-- Eliminar la función existente si existe
DROP FUNCTION IF EXISTS get_monthly_habits_breakdown(UUID, INTEGER, INTEGER);

-- Crear la función con la estructura correcta
CREATE OR REPLACE FUNCTION get_monthly_habits_breakdown(
    p_user_id UUID,
    p_year INTEGER,
    p_month INTEGER
)
RETURNS TABLE (
    category_id UUID,
    category_name TEXT,
    category_icon TEXT,
    total_habits INTEGER,
    completed_habits INTEGER,
    completion_percentage NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id as category_id,
        c.name as category_name,
        c.icon as category_icon,
        COUNT(DISTINCT uh.habit_id)::INTEGER as total_habits,
        COUNT(DISTINCT CASE 
            WHEN hl.completion_date IS NOT NULL 
            AND EXTRACT(YEAR FROM hl.completion_date) = p_year 
            AND EXTRACT(MONTH FROM hl.completion_date) = p_month 
            THEN uh.habit_id 
        END)::INTEGER as completed_habits,
        CASE 
            WHEN COUNT(DISTINCT uh.habit_id) > 0 THEN
                ROUND(
                    (COUNT(DISTINCT CASE 
                        WHEN hl.completion_date IS NOT NULL 
                        AND EXTRACT(YEAR FROM hl.completion_date) = p_year 
                        AND EXTRACT(MONTH FROM hl.completion_date) = p_month 
                        THEN uh.habit_id 
                    END)::NUMERIC / COUNT(DISTINCT uh.habit_id)::NUMERIC) * 100, 2
                )
            ELSE 0
        END as completion_percentage
    FROM categories c
    LEFT JOIN habits h ON h.category_id = c.id
    LEFT JOIN user_habits uh ON uh.habit_id = h.id AND uh.user_id = p_user_id
    LEFT JOIN habit_logs hl ON hl.habit_id = uh.habit_id
        AND EXTRACT(YEAR FROM hl.completion_date) = p_year
        AND EXTRACT(MONTH FROM hl.completion_date) = p_month
    WHERE uh.user_id = p_user_id OR uh.user_id IS NULL
    GROUP BY c.id, c.name, c.icon
    HAVING COUNT(DISTINCT uh.habit_id) > 0
    ORDER BY completion_percentage DESC, c.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Otorgar permisos a los roles anon y authenticated
GRANT EXECUTE ON FUNCTION get_monthly_habits_breakdown(UUID, INTEGER, INTEGER) TO anon;
GRANT EXECUTE ON FUNCTION get_monthly_habits_breakdown(UUID, INTEGER, INTEGER) TO authenticated;