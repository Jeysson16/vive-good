-- Corregir definitivamente la función calculate_user_progress
-- Esta migración resuelve el problema de datos siempre en 0

-- Eliminar función existente
DROP FUNCTION IF EXISTS calculate_user_progress(UUID);

-- Recrear función con cálculos corregidos
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
    WITH user_habit_data AS (
        -- Obtener todos los hábitos activos del usuario
        SELECT 
            uh.id as user_habit_id,
            uh.created_at,
            uh.is_active
        FROM user_habits uh
        WHERE uh.user_id = p_user_id 
        AND uh.is_active = true
    ),
    weekly_completions AS (
        -- Contar completaciones de esta semana
        SELECT 
            uhd.user_habit_id,
            COUNT(uhl.id) as completions_this_week
        FROM user_habit_data uhd
        LEFT JOIN user_habit_logs uhl ON uhl.user_habit_id = uhd.user_habit_id
        WHERE uhl.status = 'completed'
        AND uhl.completed_at >= DATE_TRUNC('week', CURRENT_DATE)
        AND uhl.completed_at < DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '7 days'
        GROUP BY uhd.user_habit_id
    ),
    today_completions AS (
        -- Verificar qué hábitos se completaron hoy
        SELECT 
            uhd.user_habit_id,
            CASE WHEN EXISTS(
                SELECT 1 FROM user_habit_logs uhl 
                WHERE uhl.user_habit_id = uhd.user_habit_id 
                AND uhl.status = 'completed'
                AND DATE(uhl.completed_at) = CURRENT_DATE
            ) THEN 1 ELSE 0 END as completed_today
        FROM user_habit_data uhd
    ),
    progress_stats AS (
        SELECT 
            -- Total de hábitos activos
            COUNT(uhd.user_habit_id) as total_active_habits,
            
            -- Total de completaciones esta semana (suma de todas las completaciones)
            COALESCE(SUM(wc.completions_this_week), 0) as total_weekly_completions,
            
            -- Hábitos pendientes (activos pero no completados hoy)
            COUNT(uhd.user_habit_id) - COALESCE(SUM(tc.completed_today), 0) as pending_habits,
            
            -- Nuevos hábitos (creados en los últimos 7 días)
            COUNT(CASE WHEN uhd.created_at >= NOW() - INTERVAL '7 days' THEN 1 END) as new_habits_count
            
        FROM user_habit_data uhd
        LEFT JOIN weekly_completions wc ON wc.user_habit_id = uhd.user_habit_id
        LEFT JOIN today_completions tc ON tc.user_habit_id = uhd.user_habit_id
    )
    SELECT 
        ps.total_weekly_completions::INTEGER as weekly_completed_habits,
        ps.total_active_habits::INTEGER as suggested_habits,
        ps.pending_habits::INTEGER as pending_activities,
        ps.new_habits_count::INTEGER as new_habits,
        CASE 
            WHEN ps.total_active_habits > 0 THEN 
                LEAST(100.0, GREATEST(0.0, 
                    ROUND((ps.total_weekly_completions::DECIMAL / (ps.total_active_habits::DECIMAL * 7)) * 100, 2)
                ))
            ELSE 0.0
        END as weekly_progress_percentage
    FROM progress_stats ps;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Otorgar permisos
GRANT EXECUTE ON FUNCTION calculate_user_progress(UUID) TO anon;
GRANT EXECUTE ON FUNCTION calculate_user_progress(UUID) TO authenticated;

-- Comentario
COMMENT ON FUNCTION calculate_user_progress(UUID) IS 'Calcula métricas de progreso del usuario con cálculos corregidos para evitar datos en 0';