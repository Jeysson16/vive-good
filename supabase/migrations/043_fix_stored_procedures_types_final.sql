-- CORRECCIÓN DEFINITIVA DE TIPOS EN STORED PROCEDURES
-- Eliminar y recrear todas las funciones con tipos correctos

-- Eliminar funciones existentes
DROP FUNCTION IF EXISTS get_monthly_progress_metrics(UUID, DATE, DATE);
DROP FUNCTION IF EXISTS get_category_progress_metrics(UUID, DATE, DATE);
DROP FUNCTION IF EXISTS get_weekly_trend_metrics(UUID);
DROP FUNCTION IF EXISTS get_temporal_analysis_metrics(UUID, DATE, DATE);

-- 1. FUNCIÓN: get_monthly_progress_metrics
-- IMPORTANTE: Todos los tipos deben ser TEXT para evitar conflictos
CREATE OR REPLACE FUNCTION get_monthly_progress_metrics(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE(metric_key TEXT, metric_value TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_habits INTEGER := 0;
    v_completed_habits INTEGER := 0;
    v_completion_rate DECIMAL := 0;
    v_current_streak INTEGER := 0;
    v_best_category TEXT := 'Sin categoría';
    v_habit_variety INTEGER := 0;
    v_weekly_change TEXT := '+0%';
    v_wellness_score INTEGER := 0;
    v_conversation_insights TEXT := '0 hábitos activos';
    v_healthy_adoption_pct TEXT := '0%';
    v_needs_attention_category TEXT := 'Todas por igual';
BEGIN
    -- Total de hábitos activos del usuario
    SELECT COUNT(DISTINCT uh.id)
    INTO v_total_habits
    FROM user_habits uh
    WHERE uh.user_id = p_user_id
    AND uh.is_active = true;
    
    -- Hábitos completados en el período
    SELECT COUNT(DISTINCT uhl.user_habit_id)
    INTO v_completed_habits
    FROM user_habits uh
    JOIN user_habit_logs uhl ON uh.id = uhl.user_habit_id
    WHERE uh.user_id = p_user_id
    AND uh.is_active = true
    AND uhl.status = 'completed'
    AND uhl.completed_at::date BETWEEN p_start_date AND p_end_date;
    
    -- Tasa de completado
    v_completion_rate := CASE 
        WHEN v_total_habits > 0 THEN 
            ROUND((v_completed_habits::DECIMAL / v_total_habits) * 100, 1)
        ELSE 0 
    END;
    
    -- Racha actual (días consecutivos con al menos un hábito completado)
    WITH daily_completions AS (
        SELECT DISTINCT uhl.completed_at::date as completion_date
        FROM user_habits uh
        JOIN user_habit_logs uhl ON uh.id = uhl.user_habit_id
        WHERE uh.user_id = p_user_id
        AND uhl.status = 'completed'
        ORDER BY completion_date DESC
    ),
    consecutive_days AS (
        SELECT 
            completion_date,
            ROW_NUMBER() OVER (ORDER BY completion_date DESC) as rn,
            completion_date - INTERVAL '1 day' * (ROW_NUMBER() OVER (ORDER BY completion_date DESC) - 1) as expected_date
        FROM daily_completions
    )
    SELECT COUNT(*)
    INTO v_current_streak
    FROM consecutive_days
    WHERE completion_date = expected_date::date;
    
    -- Mejor categoría (con mayor tasa de completado)
    WITH category_rates AS (
        SELECT 
            c.name,
            COUNT(DISTINCT CASE WHEN uhl.status = 'completed' THEN uh.id END)::DECIMAL / 
            NULLIF(COUNT(DISTINCT uh.id), 0) as rate
        FROM categories c
        JOIN habits h ON c.id = h.category_id
        JOIN user_habits uh ON h.id = uh.habit_id
        LEFT JOIN user_habit_logs uhl ON uh.id = uhl.user_habit_id
            AND uhl.completed_at::date BETWEEN p_start_date AND p_end_date
        WHERE uh.user_id = p_user_id
        AND uh.is_active = true
        GROUP BY c.id, c.name
        HAVING COUNT(DISTINCT uh.id) > 0
        ORDER BY rate DESC NULLS LAST
        LIMIT 1
    )
    SELECT name INTO v_best_category FROM category_rates;
    
    -- Variedad de hábitos (categorías diferentes con hábitos activos)
    SELECT COUNT(DISTINCT h.category_id)
    INTO v_habit_variety
    FROM user_habits uh
    JOIN habits h ON uh.habit_id = h.id
    WHERE uh.user_id = p_user_id
    AND uh.is_active = true;
    
    -- Score de bienestar (basado en tasa de completado)
    v_wellness_score := LEAST(100, GREATEST(0, ROUND(v_completion_rate)));
    
    -- Valores por defecto
    v_best_category := COALESCE(v_best_category, 'Sin categoría');
    v_current_streak := COALESCE(v_current_streak, 0);
    v_habit_variety := COALESCE(v_habit_variety, 0);
    
    -- Retornar resultados con tipos TEXT consistentes
    RETURN QUERY
    SELECT 'total_habits'::TEXT, v_total_habits::TEXT
    UNION ALL
    SELECT 'completed_habits'::TEXT, v_completed_habits::TEXT
    UNION ALL
    SELECT 'completion_rate'::TEXT, v_completion_rate::TEXT || '%'
    UNION ALL
    SELECT 'current_streak'::TEXT, v_current_streak::TEXT || ' días'
    UNION ALL
    SELECT 'best_category'::TEXT, v_best_category::TEXT
    UNION ALL
    SELECT 'habit_variety'::TEXT, v_habit_variety::TEXT || ' categorías'
    UNION ALL
    SELECT 'weekly_change'::TEXT, v_weekly_change::TEXT
    UNION ALL
    SELECT 'wellness_score'::TEXT, v_wellness_score::TEXT || '/100'
    UNION ALL
    SELECT 'conversation_insights'::TEXT, v_conversation_insights::TEXT
    UNION ALL
    SELECT 'healthy_adoption_pct'::TEXT, v_healthy_adoption_pct::TEXT
    UNION ALL
    SELECT 'best_adopted_category'::TEXT, v_best_category::TEXT
    UNION ALL
    SELECT 'needs_attention_category'::TEXT, v_needs_attention_category::TEXT;
END;
$$;

-- 2. FUNCIÓN: get_category_progress_metrics
-- IMPORTANTE: Retorna TEXT para evitar conflictos de tipos
CREATE OR REPLACE FUNCTION get_category_progress_metrics(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE(
    category_id TEXT,
    category_name TEXT,
    total_habits TEXT,
    completed_habits TEXT,
    completion_rate TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id::TEXT as category_id,
        c.name::TEXT as category_name,
        COUNT(DISTINCT uh.id)::TEXT as total_habits,
        COUNT(DISTINCT CASE 
            WHEN uhl.status = 'completed' 
            AND uhl.completed_at::date BETWEEN p_start_date AND p_end_date 
            THEN uh.id 
        END)::TEXT as completed_habits,
        CASE 
            WHEN COUNT(DISTINCT uh.id) > 0 THEN
                ROUND(
                    (COUNT(DISTINCT CASE 
                        WHEN uhl.status = 'completed' 
                        AND uhl.completed_at::date BETWEEN p_start_date AND p_end_date 
                        THEN uh.id 
                    END)::DECIMAL / COUNT(DISTINCT uh.id)::DECIMAL) * 100, 2
                )::TEXT || '%'
            ELSE '0%'
        END as completion_rate
    FROM categories c
    INNER JOIN habits h ON h.category_id = c.id
    INNER JOIN user_habits uh ON uh.habit_id = h.id
    LEFT JOIN user_habit_logs uhl ON uhl.user_habit_id = uh.id
    WHERE uh.user_id = p_user_id
    AND uh.is_active = true
    GROUP BY c.id, c.name
    HAVING COUNT(DISTINCT uh.id) > 0
    ORDER BY 
        CASE 
            WHEN COUNT(DISTINCT uh.id) > 0 THEN
                (COUNT(DISTINCT CASE 
                    WHEN uhl.status = 'completed' 
                    AND uhl.completed_at::date BETWEEN p_start_date AND p_end_date 
                    THEN uh.id 
                END)::DECIMAL / COUNT(DISTINCT uh.id)::DECIMAL) * 100
            ELSE 0
        END DESC, 
        c.name;
END;
$$;

-- 3. FUNCIÓN: get_weekly_trend_metrics
-- IMPORTANTE: Retorna TEXT para evitar conflictos de tipos
CREATE OR REPLACE FUNCTION get_weekly_trend_metrics(
    p_user_id UUID
)
RETURNS TABLE(
    week_start_date TEXT,
    completion_rate TEXT,
    trend_direction TEXT,
    total_completions TEXT
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
        wr.week_start::TEXT as week_start_date,
        wr.rate::TEXT || '%' as completion_rate,
        CASE 
            WHEN wr.prev_rate IS NULL THEN 'Estable'
            WHEN wr.rate > wr.prev_rate THEN 'Subiendo'
            WHEN wr.rate < wr.prev_rate THEN 'Bajando'
            ELSE 'Estable'
        END::TEXT as trend_direction,
        wr.completions::TEXT as total_completions
    FROM weekly_rates wr
    ORDER BY wr.week_start DESC;
END;
$$;

-- 4. FUNCIÓN: get_temporal_analysis_metrics
-- IMPORTANTE: Retorna TEXT para evitar conflictos de tipos
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
    
    -- Retornar resultados con tipos TEXT consistentes
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
GRANT EXECUTE ON FUNCTION get_monthly_progress_metrics(UUID, DATE, DATE) TO anon;
GRANT EXECUTE ON FUNCTION get_monthly_progress_metrics(UUID, DATE, DATE) TO authenticated;

GRANT EXECUTE ON FUNCTION get_category_progress_metrics(UUID, DATE, DATE) TO anon;
GRANT EXECUTE ON FUNCTION get_category_progress_metrics(UUID, DATE, DATE) TO authenticated;

GRANT EXECUTE ON FUNCTION get_weekly_trend_metrics(UUID) TO anon;
GRANT EXECUTE ON FUNCTION get_weekly_trend_metrics(UUID) TO authenticated;

GRANT EXECUTE ON FUNCTION get_temporal_analysis_metrics(UUID, DATE, DATE) TO anon;
GRANT EXECUTE ON FUNCTION get_temporal_analysis_metrics(UUID, DATE, DATE) TO authenticated;

-- Comentarios para documentación
COMMENT ON FUNCTION get_monthly_progress_metrics(UUID, DATE, DATE) IS 
'Obtiene métricas mensuales de progreso con tipos TEXT consistentes para evitar conflictos de PostgrestException';

COMMENT ON FUNCTION get_category_progress_metrics(UUID, DATE, DATE) IS 
'Obtiene métricas de progreso por categoría con tipos TEXT consistentes para evitar conflictos de PostgrestException';

COMMENT ON FUNCTION get_weekly_trend_metrics(UUID) IS 
'Obtiene métricas de tendencias semanales con tipos TEXT consistentes para evitar conflictos de PostgrestException';

COMMENT ON FUNCTION get_temporal_analysis_metrics(UUID, DATE, DATE) IS 
'Obtiene métricas de análisis temporal con tipos TEXT consistentes para evitar conflictos de PostgrestException';