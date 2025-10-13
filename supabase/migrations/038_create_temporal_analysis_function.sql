-- Función para análisis temporal de hábitos (mejor día, hora más productiva, hábito más consistente)
CREATE OR REPLACE FUNCTION get_temporal_analysis_metrics(p_user_id UUID, p_start_date DATE DEFAULT NULL, p_end_date DATE DEFAULT NULL)
RETURNS TABLE (
    metric_key TEXT,
    metric_value TEXT
) AS $$
DECLARE
    v_start_date DATE;
    v_end_date DATE;
    v_best_day TEXT;
    v_most_productive_hour TEXT;
    v_most_consistent_habit TEXT;
BEGIN
    -- Establecer fechas por defecto (últimos 30 días)
    v_start_date := COALESCE(p_start_date, CURRENT_DATE - INTERVAL '30 days');
    v_end_date := COALESCE(p_end_date, CURRENT_DATE);
    
    -- 1. MEJOR DÍA DE LA SEMANA
    -- Encontrar el día con más hábitos completados
    WITH daily_completions AS (
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
        JOIN user_habit_logs uhl ON uh.id = uhl.user_habit_id
        WHERE uh.user_id = p_user_id
        AND uhl.status = 'completed'
        AND uhl.completed_at::date BETWEEN v_start_date AND v_end_date
        GROUP BY EXTRACT(DOW FROM uhl.completed_at)
        ORDER BY completions DESC
        LIMIT 1
    )
    SELECT day_name INTO v_best_day FROM daily_completions;
    
    v_best_day := COALESCE(v_best_day, 'Lun');
    
    -- 2. HORA MÁS PRODUCTIVA
    -- Encontrar la hora con más hábitos completados
    WITH hourly_completions AS (
        SELECT 
            EXTRACT(HOUR FROM uhl.completed_at) as hour_24,
            COUNT(*) as completions
        FROM user_habits uh
        JOIN user_habit_logs uhl ON uh.id = uhl.user_habit_id
        WHERE uh.user_id = p_user_id
        AND uhl.status = 'completed'
        AND uhl.completed_at::date BETWEEN v_start_date AND v_end_date
        GROUP BY EXTRACT(HOUR FROM uhl.completed_at)
        ORDER BY completions DESC
        LIMIT 1
    )
    SELECT 
        CASE 
            WHEN hour_24 = 0 THEN '12:00 AM'
            WHEN hour_24 < 12 THEN hour_24::TEXT || ':00 AM'
            WHEN hour_24 = 12 THEN '12:00 PM'
            ELSE (hour_24 - 12)::TEXT || ':00 PM'
        END
    INTO v_most_productive_hour
    FROM hourly_completions;
    
    v_most_productive_hour := COALESCE(v_most_productive_hour, '8:00 AM');
    
    -- 3. HÁBITO MÁS CONSISTENTE
    -- Encontrar el hábito con mayor frecuencia de completado
    WITH habit_consistency AS (
        SELECT 
            h.name as habit_name,
            COUNT(*) as total_completions,
            COUNT(DISTINCT uhl.completed_at::date) as days_completed,
            ROUND(COUNT(DISTINCT uhl.completed_at::date)::DECIMAL / EXTRACT(DAYS FROM (v_end_date - v_start_date + 1)) * 100, 1) as consistency_rate
        FROM user_habits uh
        JOIN habits h ON uh.habit_id = h.id
        JOIN user_habit_logs uhl ON uh.id = uhl.user_habit_id
        WHERE uh.user_id = p_user_id
        AND uhl.status = 'completed'
        AND uhl.completed_at::date BETWEEN v_start_date AND v_end_date
        AND uh.is_active = true
        GROUP BY h.id, h.name
        HAVING COUNT(*) >= 3  -- Al menos 3 completados para ser considerado consistente
        ORDER BY consistency_rate DESC, total_completions DESC
        LIMIT 1
    )
    SELECT habit_name INTO v_most_consistent_habit FROM habit_consistency;
    
    v_most_consistent_habit := COALESCE(v_most_consistent_habit, 'Ninguno registrado');
    
    -- RETORNAR RESULTADOS
    RETURN QUERY
    SELECT 'best_day'::TEXT, v_best_day
    UNION ALL
    SELECT 'most_productive_hour'::TEXT, v_most_productive_hour
    UNION ALL
    SELECT 'most_consistent_habit'::TEXT, v_most_consistent_habit;
    
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Otorgar permisos
GRANT EXECUTE ON FUNCTION get_temporal_analysis_metrics(UUID, DATE, DATE) TO authenticated;