-- Crear stored procedures faltantes para corregir PostgrestException en getMonthlyIndicators

-- 1. FUNCIÓN: get_category_progress_metrics
-- Obtiene métricas de progreso por categoría para un período específico
CREATE OR REPLACE FUNCTION get_category_progress_metrics(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE(
    category_id UUID,
    category_name TEXT,
    total_habits INTEGER,
    completed_habits INTEGER,
    completion_rate DECIMAL
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id as category_id,
        c.name as category_name,
        COUNT(DISTINCT uh.id)::INTEGER as total_habits,
        COUNT(DISTINCT CASE 
            WHEN uhl.status = 'completed' 
            AND uhl.completed_at::date BETWEEN p_start_date AND p_end_date 
            THEN uh.id 
        END)::INTEGER as completed_habits,
        CASE 
            WHEN COUNT(DISTINCT uh.id) > 0 THEN
                ROUND(
                    (COUNT(DISTINCT CASE 
                        WHEN uhl.status = 'completed' 
                        AND uhl.completed_at::date BETWEEN p_start_date AND p_end_date 
                        THEN uh.id 
                    END)::DECIMAL / COUNT(DISTINCT uh.id)::DECIMAL) * 100, 2
                )
            ELSE 0
        END as completion_rate
    FROM categories c
    INNER JOIN habits h ON h.category_id = c.id
    INNER JOIN user_habits uh ON uh.habit_id = h.id
    LEFT JOIN user_habit_logs uhl ON uhl.user_habit_id = uh.id
    WHERE uh.user_id = p_user_id
    AND uh.is_active = true
    GROUP BY c.id, c.name
    HAVING COUNT(DISTINCT uh.id) > 0
    ORDER BY completion_rate DESC, category_name;
END;
$$;

-- 2. FUNCIÓN: get_weekly_trend_metrics
-- Obtiene métricas de tendencias semanales para un usuario
CREATE OR REPLACE FUNCTION get_weekly_trend_metrics(
    p_user_id UUID
)
RETURNS TABLE(
    week_start_date DATE,
    completion_rate DECIMAL,
    trend_direction TEXT,
    total_completions INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH weekly_data AS (
        SELECT 
            DATE_TRUNC('week', uhl.completed_at::date)::date as week_start,
            COUNT(CASE WHEN uhl.status = 'completed' THEN 1 END) as completions,
            COUNT(DISTINCT uh.id) as total_habits
        FROM user_habits uh
        LEFT JOIN user_habit_logs uhl ON uhl.user_habit_id = uh.id
        WHERE uh.user_id = p_user_id
        AND uh.is_active = true
        AND uhl.completed_at >= CURRENT_DATE - INTERVAL '4 weeks'
        GROUP BY DATE_TRUNC('week', uhl.completed_at::date)::date
        ORDER BY week_start DESC
        LIMIT 4
    ),
    weekly_rates AS (
        SELECT 
            week_start,
            completions,
            total_habits,
            CASE 
                WHEN total_habits > 0 THEN 
                    ROUND((completions::DECIMAL / (total_habits * 7)) * 100, 2)
                ELSE 0 
            END as rate,
            LAG(CASE 
                WHEN total_habits > 0 THEN 
                    ROUND((completions::DECIMAL / (total_habits * 7)) * 100, 2)
                ELSE 0 
            END) OVER (ORDER BY week_start) as prev_rate
        FROM weekly_data
    )
    SELECT 
        wr.week_start as week_start_date,
        wr.rate as completion_rate,
        CASE 
            WHEN wr.prev_rate IS NULL THEN 'Estable'
            WHEN wr.rate > wr.prev_rate THEN 'Subiendo'
            WHEN wr.rate < wr.prev_rate THEN 'Bajando'
            ELSE 'Estable'
        END as trend_direction,
        wr.completions as total_completions
    FROM weekly_rates wr
    ORDER BY wr.week_start DESC;
END;
$$;

-- 3. FUNCIÓN: get_temporal_analysis_metrics
-- Obtiene métricas de análisis temporal (mejor día, hora más productiva, etc.)
CREATE OR REPLACE FUNCTION get_temporal_analysis_metrics(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE(metric_key TEXT, metric_value TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_best_day TEXT := 'Lun';
    v_most_productive_hour TEXT := '8:00 AM';
    v_most_consistent_habit TEXT := 'Ninguno registrado';
    v_total_logs INTEGER := 0;
BEGIN
    -- Obtener el día de la semana con más completaciones
    WITH day_completions AS (
        SELECT 
            CASE EXTRACT(DOW FROM uhl.completed_at)
                WHEN 0 THEN 'Dom'
                WHEN 1 THEN 'Lun'
                WHEN 2 THEN 'Mar'
                WHEN 3 THEN 'Mié'
                WHEN 4 THEN 'Jue'
                WHEN 5 THEN 'Vie'
                WHEN 6 THEN 'Sáb'
            END as day_name,
            COUNT(*) as completions
        FROM user_habits uh
        JOIN user_habit_logs uhl ON uhl.user_habit_id = uh.id
        WHERE uh.user_id = p_user_id
        AND uhl.status = 'completed'
        AND uhl.completed_at::date BETWEEN p_start_date AND p_end_date
        GROUP BY EXTRACT(DOW FROM uhl.completed_at)
        ORDER BY completions DESC
        LIMIT 1
    )
    SELECT day_name INTO v_best_day
    FROM day_completions;
    
    -- Obtener la hora más productiva
    WITH hour_completions AS (
        SELECT 
            EXTRACT(HOUR FROM uhl.completed_at) as hour_num,
            COUNT(*) as completions
        FROM user_habits uh
        JOIN user_habit_logs uhl ON uhl.user_habit_id = uh.id
        WHERE uh.user_id = p_user_id
        AND uhl.status = 'completed'
        AND uhl.completed_at::date BETWEEN p_start_date AND p_end_date
        GROUP BY EXTRACT(HOUR FROM uhl.completed_at)
        ORDER BY completions DESC
        LIMIT 1
    )
    SELECT 
        CASE 
            WHEN hour_num = 0 THEN '12:00 AM'
            WHEN hour_num < 12 THEN hour_num || ':00 AM'
            WHEN hour_num = 12 THEN '12:00 PM'
            ELSE (hour_num - 12) || ':00 PM'
        END
    INTO v_most_productive_hour
    FROM hour_completions;
    
    -- Obtener el hábito más consistente
    WITH habit_consistency AS (
        SELECT 
            h.name,
            COUNT(DISTINCT uhl.completed_at::date) as days_completed,
            COUNT(*) as total_logs
        FROM user_habits uh
        JOIN habits h ON h.id = uh.habit_id
        JOIN user_habit_logs uhl ON uhl.user_habit_id = uh.id
        WHERE uh.user_id = p_user_id
        AND uhl.status = 'completed'
        AND uhl.completed_at::date BETWEEN p_start_date AND p_end_date
        GROUP BY h.id, h.name
        ORDER BY days_completed DESC, total_logs DESC
        LIMIT 1
    )
    SELECT name INTO v_most_consistent_habit
    FROM habit_consistency;
    
    -- Obtener total de logs
    SELECT COUNT(*)
    INTO v_total_logs
    FROM user_habits uh
    JOIN user_habit_logs uhl ON uhl.user_habit_id = uh.id
    WHERE uh.user_id = p_user_id
    AND uhl.status = 'completed'
    AND uhl.completed_at::date BETWEEN p_start_date AND p_end_date;
    
    -- Valores por defecto si no hay datos
    v_best_day := COALESCE(v_best_day, 'Lun');
    v_most_productive_hour := COALESCE(v_most_productive_hour, '8:00 AM');
    v_most_consistent_habit := COALESCE(v_most_consistent_habit, 'Ninguno registrado');
    
    -- Retornar resultados
    RETURN QUERY
    SELECT 'best_day'::TEXT, v_best_day::TEXT
    UNION ALL
    SELECT 'most_productive_hour'::TEXT, v_most_productive_hour::TEXT
    UNION ALL
    SELECT 'most_consistent_habit'::TEXT, v_most_consistent_habit::TEXT
    UNION ALL
    SELECT 'total_logs'::TEXT, v_total_logs::TEXT;
END;
$$;

-- Otorgar permisos a los roles
GRANT EXECUTE ON FUNCTION get_category_progress_metrics(UUID, DATE, DATE) TO anon;
GRANT EXECUTE ON FUNCTION get_category_progress_metrics(UUID, DATE, DATE) TO authenticated;

GRANT EXECUTE ON FUNCTION get_weekly_trend_metrics(UUID) TO anon;
GRANT EXECUTE ON FUNCTION get_weekly_trend_metrics(UUID) TO authenticated;

GRANT EXECUTE ON FUNCTION get_temporal_analysis_metrics(UUID, DATE, DATE) TO anon;
GRANT EXECUTE ON FUNCTION get_temporal_analysis_metrics(UUID, DATE, DATE) TO authenticated;

-- Comentarios para documentación
COMMENT ON FUNCTION get_category_progress_metrics(UUID, DATE, DATE) IS 
'Obtiene métricas de progreso por categoría para un período específico, incluyendo total de hábitos, hábitos completados y tasa de completado';

COMMENT ON FUNCTION get_weekly_trend_metrics(UUID) IS 
'Obtiene métricas de tendencias semanales para las últimas 4 semanas, incluyendo dirección de tendencia y tasa de completado';

COMMENT ON FUNCTION get_temporal_analysis_metrics(UUID, DATE, DATE) IS 
'Obtiene métricas de análisis temporal como mejor día de la semana, hora más productiva y hábito más consistente';