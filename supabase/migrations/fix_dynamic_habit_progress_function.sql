-- Corregir función get_dynamic_habit_progress para usar nombres de categorías correctos
-- El problema era que buscaba categorías en minúsculas pero las reales están con mayúsculas

CREATE OR REPLACE FUNCTION get_dynamic_habit_progress(p_user_id UUID)
RETURNS TABLE (
    hydration_progress INTEGER,
    hydration_goal INTEGER,
    sleep_progress INTEGER,
    sleep_goal INTEGER,
    activity_progress INTEGER,
    activity_goal INTEGER
) AS $$
DECLARE
    week_start DATE;
    week_end DATE;
BEGIN
    -- Calcular el inicio y fin de la semana actual (lunes a domingo)
    week_start := DATE_TRUNC('week', CURRENT_DATE);
    week_end := week_start + INTERVAL '6 days';
    
    RETURN QUERY
    WITH habit_categories AS (
        -- Obtener categorías de hábitos con nombres reales
        SELECT 
            c.id as category_id,
            c.name as category_name -- Usar nombre real, no en minúsculas
        FROM categories c
    ),
    user_habit_logs_week AS (
        -- Logs de hábitos de la semana actual
        SELECT 
            uhl.user_habit_id,
            uhl.completed_at,
            uh.user_id,
            h.category_id,
            hc.category_name,
            DATE(uhl.completed_at) as completion_date
        FROM user_habit_logs uhl
        INNER JOIN user_habits uh ON uh.id = uhl.user_habit_id
        INNER JOIN habits h ON h.id = uh.habit_id
        INNER JOIN habit_categories hc ON hc.category_id = h.category_id
        WHERE uh.user_id = p_user_id
        AND uhl.status = 'completed'
        AND DATE(uhl.completed_at) >= week_start
        AND DATE(uhl.completed_at) <= week_end
    ),
    daily_completions AS (
        -- Contar días únicos de completación por categoría
        SELECT 
            category_name,
            COUNT(DISTINCT completion_date) as days_completed
        FROM user_habit_logs_week
        -- Buscar categorías con nombres reales (con mayúsculas)
        WHERE category_name IN ('Hidratación', 'Sueño', 'Actividad Física', 'Alimentación', 'Bienestar Mental', 'Productividad')
        GROUP BY category_name
    )
    SELECT 
        -- Hidratación: buscar categoría exacta 'Hidratación'
        COALESCE((
            SELECT days_completed 
            FROM daily_completions 
            WHERE category_name = 'Hidratación'
            LIMIT 1
        ), 0)::INTEGER as hydration_progress,
        5 as hydration_goal, -- Meta de 5 días por semana
        
        -- Sueño: buscar categoría exacta 'Sueño'
        COALESCE((
            SELECT days_completed 
            FROM daily_completions 
            WHERE category_name = 'Sueño'
            LIMIT 1
        ), 0)::INTEGER as sleep_progress,
        5 as sleep_goal, -- Meta de 5 días por semana
        
        -- Actividad: buscar categoría exacta 'Actividad Física'
        COALESCE((
            SELECT days_completed 
            FROM daily_completions 
            WHERE category_name = 'Actividad Física'
            LIMIT 1
        ), 0)::INTEGER as activity_progress,
        5 as activity_goal; -- Meta de 5 días por semana
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Otorgar permisos
GRANT EXECUTE ON FUNCTION get_dynamic_habit_progress(UUID) TO anon;
GRANT EXECUTE ON FUNCTION get_dynamic_habit_progress(UUID) TO authenticated;

-- Comentario
COMMENT ON FUNCTION get_dynamic_habit_progress(UUID) IS 'Calcula el progreso dinámico de hábitos basado en logs reales de la semana actual - CORREGIDO para usar nombres de categorías correctos';