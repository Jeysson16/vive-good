-- Fix monthly habits breakdown stored procedure types
-- This migration fixes the type mismatch error and adds missing fields

-- Drop existing function to avoid conflicts
DROP FUNCTION IF EXISTS get_monthly_habits_breakdown(UUID, INTEGER, INTEGER);

-- Create the corrected function with proper types
CREATE OR REPLACE FUNCTION get_monthly_habits_breakdown(
    p_user_id UUID,
    p_year INTEGER,
    p_month INTEGER
)
RETURNS TABLE (
    category_id UUID,
    category_name VARCHAR(100),  -- Changed from TEXT to VARCHAR(100) to match table definition
    category_icon VARCHAR(50),   -- Changed from TEXT to VARCHAR(50) to match table definition
    category_color VARCHAR(7),   -- Added missing field
    total_habits INTEGER,
    completed_habits INTEGER,
    completion_percentage NUMERIC,
    total_logs INTEGER,          -- Added missing field
    completed_logs INTEGER       -- Added missing field
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id as category_id,
        c.name as category_name,
        c.icon as category_icon,
        c.color as category_color,
        COUNT(DISTINCT uh.habit_id)::INTEGER as total_habits,
        COUNT(DISTINCT CASE 
            WHEN uhl.completed_at IS NOT NULL 
            AND EXTRACT(YEAR FROM uhl.completed_at) = p_year 
            AND EXTRACT(MONTH FROM uhl.completed_at) = p_month 
            THEN uh.habit_id 
        END)::INTEGER as completed_habits,
        CASE 
            WHEN COUNT(DISTINCT uh.habit_id) > 0 THEN
                ROUND(
                    (COUNT(DISTINCT CASE 
                        WHEN uhl.completed_at IS NOT NULL 
                        AND EXTRACT(YEAR FROM uhl.completed_at) = p_year 
                        AND EXTRACT(MONTH FROM uhl.completed_at) = p_month 
                        THEN uh.habit_id 
                    END)::NUMERIC / COUNT(DISTINCT uh.habit_id)::NUMERIC) * 100, 2
                )
            ELSE 0
        END as completion_percentage,
        COUNT(uhl.id)::INTEGER as total_logs,
        COUNT(CASE 
            WHEN uhl.status = 'completed' 
            AND EXTRACT(YEAR FROM uhl.completed_at) = p_year 
            AND EXTRACT(MONTH FROM uhl.completed_at) = p_month 
            THEN 1 
        END)::INTEGER as completed_logs
    FROM categories c
    LEFT JOIN habits h ON h.category_id = c.id
    LEFT JOIN user_habits uh ON uh.habit_id = h.id AND uh.user_id = p_user_id
    LEFT JOIN user_habit_logs uhl ON uhl.user_habit_id = uh.id
        AND EXTRACT(YEAR FROM uhl.completed_at) = p_year
        AND EXTRACT(MONTH FROM uhl.completed_at) = p_month
    WHERE uh.user_id = p_user_id OR uh.user_id IS NULL
    GROUP BY c.id, c.name, c.icon, c.color
    HAVING COUNT(DISTINCT uh.habit_id) > 0
    ORDER BY completion_percentage DESC, c.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions to the necessary roles
GRANT EXECUTE ON FUNCTION get_monthly_habits_breakdown(UUID, INTEGER, INTEGER) TO anon;
GRANT EXECUTE ON FUNCTION get_monthly_habits_breakdown(UUID, INTEGER, INTEGER) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION get_monthly_habits_breakdown(UUID, INTEGER, INTEGER) IS 
'Returns monthly habits breakdown by category with proper type matching for HabitBreakdownModel';