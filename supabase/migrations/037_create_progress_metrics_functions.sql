-- Stored procedures para calcular métricas de progreso basándose en datos reales
-- Estas funciones calculan dinámicamente las métricas usando user_habits, user_habit_logs, categories y habits

-- Función para obtener métricas mensuales de progreso
CREATE OR REPLACE FUNCTION get_monthly_progress_metrics(p_user_id UUID, p_start_date DATE DEFAULT NULL, p_end_date DATE DEFAULT NULL)
RETURNS TABLE (
    metric_key TEXT,
    metric_value TEXT
) AS $$
DECLARE
    v_start_date DATE;
    v_end_date DATE;
    v_total_habits INTEGER;
    v_completed_habits INTEGER;
    v_completion_rate DECIMAL;
    v_current_streak INTEGER;
    v_best_category TEXT;
    v_best_category_rate DECIMAL;
    v_wellness_score INTEGER;
    v_consistency_score DECIMAL;
    v_adoption_trend TEXT;
BEGIN
    -- Establecer fechas por defecto (últimos 30 días)
    v_start_date := COALESCE(p_start_date, CURRENT_DATE - INTERVAL '30 days');
    v_end_date := COALESCE(p_end_date, CURRENT_DATE);
    
    -- 1. MÉTRICAS BÁSICAS DE HÁBITOS
    -- Total de hábitos activos del usuario
    SELECT COUNT(*)
    INTO v_total_habits
    FROM user_habits uh
    JOIN habits h ON uh.habit_id = h.id
    WHERE uh.user_id = p_user_id 
    AND uh.is_active = true;
    
    -- Hábitos completados en el período
    SELECT COUNT(DISTINCT uh.id)
    INTO v_completed_habits
    FROM user_habits uh
    JOIN user_habit_logs uhl ON uh.id = uhl.user_habit_id
    WHERE uh.user_id = p_user_id
    AND uh.is_active = true
    AND uhl.status = 'completed'
    AND uhl.completed_at::date BETWEEN v_start_date AND v_end_date;
    
    -- Tasa de completado
    v_completion_rate := CASE 
        WHEN v_total_habits > 0 THEN (v_completed_habits::DECIMAL / v_total_habits) * 100
        ELSE 0 
    END;
    
    -- 2. RACHA ACTUAL
    -- Calcular racha actual de días consecutivos con al menos un hábito completado
    WITH daily_completions AS (
        SELECT DISTINCT uhl.completed_at::date as completion_date
        FROM user_habits uh
        JOIN user_habit_logs uhl ON uh.id = uhl.user_habit_id
        WHERE uh.user_id = p_user_id
        AND uhl.status = 'completed'
        AND uhl.completed_at::date <= CURRENT_DATE
        ORDER BY completion_date DESC
    ),
    consecutive_days AS (
        SELECT 
            completion_date,
            ROW_NUMBER() OVER (ORDER BY completion_date DESC) as rn,
            completion_date + (ROW_NUMBER() OVER (ORDER BY completion_date DESC) || ' days')::interval as expected_date
        FROM daily_completions
    )
    SELECT COUNT(*)
    INTO v_current_streak
    FROM consecutive_days
    WHERE expected_date::date = CURRENT_DATE + (rn || ' days')::interval::date;
    
    v_current_streak := COALESCE(v_current_streak, 0);
    
    -- 3. MEJOR CATEGORÍA
    -- Encontrar la categoría con mejor tasa de completado
    WITH category_performance AS (
        SELECT 
            c.name as category_name,
            COUNT(DISTINCT uh.id) as total_habits,
            COUNT(DISTINCT CASE WHEN uhl.status = 'completed' THEN uh.id END) as completed_habits,
            CASE 
                WHEN COUNT(DISTINCT uh.id) > 0 THEN 
                    (COUNT(DISTINCT CASE WHEN uhl.status = 'completed' THEN uh.id END)::DECIMAL / COUNT(DISTINCT uh.id)) * 100
                ELSE 0 
            END as completion_rate
        FROM categories c
        JOIN habits h ON c.id = h.category_id
        JOIN user_habits uh ON h.id = uh.habit_id
        LEFT JOIN user_habit_logs uhl ON uh.id = uhl.user_habit_id 
            AND uhl.completed_at::date BETWEEN v_start_date AND v_end_date
        WHERE uh.user_id = p_user_id
        AND uh.is_active = true
        GROUP BY c.id, c.name
        HAVING COUNT(DISTINCT uh.id) > 0
        ORDER BY completion_rate DESC, total_habits DESC
        LIMIT 1
    )
    SELECT category_name, completion_rate
    INTO v_best_category, v_best_category_rate
    FROM category_performance;
    
    v_best_category := COALESCE(v_best_category, 'Sin categoría');
    v_best_category_rate := COALESCE(v_best_category_rate, 0);
    
    -- 4. PUNTUACIÓN DE BIENESTAR (1-100)
    -- Basada en: tasa de completado (40%) + racha actual (30%) + diversidad de categorías (30%)
    WITH category_diversity AS (
        SELECT COUNT(DISTINCT c.id) as active_categories
        FROM categories c
        JOIN habits h ON c.id = h.category_id
        JOIN user_habits uh ON h.id = uh.habit_id
        WHERE uh.user_id = p_user_id
        AND uh.is_active = true
    )
    SELECT 
        LEAST(100, GREATEST(0, 
            (v_completion_rate * 0.4) + 
            (LEAST(v_current_streak * 10, 30) * 1.0) + 
            (LEAST(cd.active_categories * 7.5, 30) * 1.0)
        ))::INTEGER
    INTO v_wellness_score
    FROM category_diversity cd;
    
    -- 5. PUNTUACIÓN DE CONSISTENCIA
    -- Basada en la regularidad de completado en los últimos 7 días
    WITH daily_activity AS (
        SELECT 
            generate_series(CURRENT_DATE - INTERVAL '6 days', CURRENT_DATE, '1 day'::interval)::date as day,
            COALESCE(COUNT(DISTINCT uhl.user_habit_id), 0) as habits_completed
        FROM generate_series(CURRENT_DATE - INTERVAL '6 days', CURRENT_DATE, '1 day'::interval) gs(day)
        LEFT JOIN user_habit_logs uhl ON uhl.completed_at::date = gs.day
        LEFT JOIN user_habits uh ON uhl.user_habit_id = uh.id
        WHERE uh.user_id = p_user_id OR uh.user_id IS NULL
        GROUP BY gs.day
    )
    SELECT 
        CASE 
            WHEN COUNT(*) = 0 THEN 0
            ELSE (COUNT(CASE WHEN habits_completed > 0 THEN 1 END)::DECIMAL / COUNT(*)) * 100
        END
    INTO v_consistency_score
    FROM daily_activity;
    
    -- 6. TENDENCIA DE ADOPCIÓN
    -- Comparar últimos 15 días vs 15 días anteriores
    WITH recent_period AS (
        SELECT COUNT(DISTINCT uhl.user_habit_id) as recent_completions
        FROM user_habits uh
        JOIN user_habit_logs uhl ON uh.id = uhl.user_habit_id
        WHERE uh.user_id = p_user_id
        AND uhl.status = 'completed'
        AND uhl.completed_at::date BETWEEN CURRENT_DATE - INTERVAL '14 days' AND CURRENT_DATE
    ),
    previous_period AS (
        SELECT COUNT(DISTINCT uhl.user_habit_id) as previous_completions
        FROM user_habits uh
        JOIN user_habit_logs uhl ON uh.id = uhl.user_habit_id
        WHERE uh.user_id = p_user_id
        AND uhl.status = 'completed'
        AND uhl.completed_at::date BETWEEN CURRENT_DATE - INTERVAL '29 days' AND CURRENT_DATE - INTERVAL '15 days'
    )
    SELECT 
        CASE 
            WHEN rp.recent_completions > pp.previous_completions THEN 'Mejorando'
            WHEN rp.recent_completions < pp.previous_completions THEN 'Declinando'
            ELSE 'Estable'
        END
    INTO v_adoption_trend
    FROM recent_period rp, previous_period pp;
    
    -- RETORNAR RESULTADOS
    RETURN QUERY
    SELECT 'total_habits'::TEXT, v_total_habits::TEXT
    UNION ALL
    SELECT 'completed_habits'::TEXT, v_completed_habits::TEXT
    UNION ALL
    SELECT 'completion_rate'::TEXT, ROUND(v_completion_rate, 1)::TEXT || '%'
    UNION ALL
    SELECT 'current_streak'::TEXT, v_current_streak::TEXT || ' días'
    UNION ALL
    SELECT 'best_category'::TEXT, v_best_category
    UNION ALL
    SELECT 'best_category_rate'::TEXT, ROUND(v_best_category_rate, 1)::TEXT || '%'
    UNION ALL
    SELECT 'wellness_score'::TEXT, v_wellness_score::TEXT || '/100'
    UNION ALL
    SELECT 'consistency_score'::TEXT, ROUND(v_consistency_score, 1)::TEXT || '%'
    UNION ALL
    SELECT 'adoption_trend'::TEXT, v_adoption_trend;
    
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para obtener progreso por categorías
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

-- Función para obtener análisis de tendencias semanales
CREATE OR REPLACE FUNCTION get_weekly_trend_metrics(p_user_id UUID)
RETURNS TABLE (
    week_start DATE,
    habits_completed INTEGER,
    completion_rate DECIMAL,
    trend_direction TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH weekly_data AS (
        SELECT 
            date_trunc('week', uhl.completed_at::date)::date as week_start,
            COUNT(DISTINCT uhl.user_habit_id) as habits_completed,
            COUNT(DISTINCT uh.id) as total_active_habits
        FROM user_habits uh
        LEFT JOIN user_habit_logs uhl ON uh.id = uhl.user_habit_id 
            AND uhl.status = 'completed'
            AND uhl.completed_at >= CURRENT_DATE - INTERVAL '4 weeks'
        WHERE uh.user_id = p_user_id
        AND uh.is_active = true
        GROUP BY date_trunc('week', uhl.completed_at::date)::date
        ORDER BY week_start DESC
        LIMIT 4
    ),
    weekly_rates AS (
        SELECT 
            week_start,
            habits_completed,
            CASE 
                WHEN total_active_habits > 0 THEN 
                    ROUND((habits_completed::DECIMAL / total_active_habits) * 100, 1)
                ELSE 0 
            END as completion_rate,
            LAG(habits_completed) OVER (ORDER BY week_start) as prev_completed
        FROM weekly_data
    )
    SELECT 
        wr.week_start,
        wr.habits_completed,
        wr.completion_rate,
        CASE 
            WHEN wr.prev_completed IS NULL THEN 'Inicial'
            WHEN wr.habits_completed > wr.prev_completed THEN 'Subiendo'
            WHEN wr.habits_completed < wr.prev_completed THEN 'Bajando'
            ELSE 'Estable'
        END as trend_direction
    FROM weekly_rates wr
    ORDER BY wr.week_start DESC;
    
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Otorgar permisos
GRANT EXECUTE ON FUNCTION get_monthly_progress_metrics(UUID, DATE, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION get_category_progress_metrics(UUID, DATE, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION get_weekly_trend_metrics(UUID) TO authenticated;