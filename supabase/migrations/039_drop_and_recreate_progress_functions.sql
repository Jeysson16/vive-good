-- Eliminar y recrear las funciones de progreso para corregir errores

-- Eliminar funciones existentes
DROP FUNCTION IF EXISTS get_monthly_progress_metrics(UUID, DATE, DATE);
DROP FUNCTION IF EXISTS get_category_progress_metrics(UUID, DATE, DATE);
DROP FUNCTION IF EXISTS get_weekly_trend_metrics(UUID);

-- Recrear get_monthly_progress_metrics corregida
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
    v_weekly_change DECIMAL := 0;
    v_wellness_score INTEGER := 0;
    v_conversation_insights TEXT := '0 hábitos activos';
    v_healthy_adoption_pct TEXT := '0/100';
    v_needs_attention_category TEXT := 'Todas por igual';
BEGIN
    -- 1. MÉTRICAS BÁSICAS
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
        WHEN v_total_habits > 0 THEN (v_completed_habits::DECIMAL / v_total_habits) * 100
        ELSE 0 
    END;
    
    -- 2. RACHA ACTUAL (simplificada)
    SELECT COUNT(DISTINCT uhl.completed_at::date)
    INTO v_current_streak
    FROM user_habits uh
    JOIN user_habit_logs uhl ON uh.id = uhl.user_habit_id
    WHERE uh.user_id = p_user_id
    AND uhl.status = 'completed'
    AND uhl.completed_at::date >= CURRENT_DATE - INTERVAL '7 days';
    
    v_current_streak := COALESCE(v_current_streak, 0);
    
    -- 3. MEJOR CATEGORÍA
    WITH category_performance AS (
        SELECT 
            c.name as category_name,
            COUNT(DISTINCT uh.id) as total_habits,
            COUNT(DISTINCT CASE WHEN uhl.status = 'completed' THEN uhl.user_habit_id END) as completed_habits
        FROM user_habits uh
        JOIN habits h ON uh.habit_id = h.id
        JOIN categories c ON h.category_id = c.id
        LEFT JOIN user_habit_logs uhl ON uh.id = uhl.user_habit_id 
            AND uhl.completed_at::date BETWEEN p_start_date AND p_end_date
        WHERE uh.user_id = p_user_id
        AND uh.is_active = true
        GROUP BY c.id, c.name
        HAVING COUNT(DISTINCT uh.id) > 0
    )
    SELECT category_name
    INTO v_best_category
    FROM category_performance
    ORDER BY completed_habits DESC, total_habits DESC
    LIMIT 1;
    
    v_best_category := COALESCE(v_best_category, 'Sin categoría');
    
    -- 4. VARIEDAD DE HÁBITOS
    SELECT COUNT(DISTINCT h.category_id)
    INTO v_habit_variety
    FROM user_habits uh
    JOIN habits h ON uh.habit_id = h.id
    WHERE uh.user_id = p_user_id
    AND uh.is_active = true;
    
    v_habit_variety := COALESCE(v_habit_variety, 0);
    
    -- 5. CAMBIO SEMANAL (simplificado)
    WITH weekly_stats AS (
        SELECT 
            CASE 
                WHEN uhl.completed_at::date >= CURRENT_DATE - INTERVAL '7 days' THEN 'current_week'
                WHEN uhl.completed_at::date >= CURRENT_DATE - INTERVAL '14 days' 
                     AND uhl.completed_at::date < CURRENT_DATE - INTERVAL '7 days' THEN 'previous_week'
            END as week_period,
            COUNT(*) as completions
        FROM user_habits uh
        JOIN user_habit_logs uhl ON uh.id = uhl.user_habit_id
        WHERE uh.user_id = p_user_id
        AND uhl.status = 'completed'
        AND uhl.completed_at::date >= CURRENT_DATE - INTERVAL '14 days'
        GROUP BY week_period
    )
    SELECT 
        CASE 
            WHEN MAX(CASE WHEN week_period = 'previous_week' THEN completions ELSE 0 END) > 0 THEN
                ((MAX(CASE WHEN week_period = 'current_week' THEN completions ELSE 0 END) - 
                  MAX(CASE WHEN week_period = 'previous_week' THEN completions ELSE 0 END))::DECIMAL / 
                 MAX(CASE WHEN week_period = 'previous_week' THEN completions ELSE 0 END)) * 100
            ELSE 0
        END
    INTO v_weekly_change
    FROM weekly_stats;
    
    v_weekly_change := COALESCE(v_weekly_change, 0);
    
    -- 6. WELLNESS SCORE (basado en tasa de completado)
    v_wellness_score := ROUND(v_completion_rate)::INTEGER;
    
    -- 7. CONVERSATION INSIGHTS
    v_conversation_insights := v_total_habits || ' hábitos activos';
    
    -- 8. HEALTHY ADOPTION PERCENTAGE
    v_healthy_adoption_pct := v_completed_habits || '/' || v_total_habits;
    
    -- 9. NEEDS ATTENTION CATEGORY (categoría con menos completados)
    WITH category_performance AS (
        SELECT 
            c.name as category_name,
            COUNT(DISTINCT uh.id) as total_habits,
            COUNT(DISTINCT CASE WHEN uhl.status = 'completed' THEN uhl.user_habit_id END) as completed_habits
        FROM user_habits uh
        JOIN habits h ON uh.habit_id = h.id
        JOIN categories c ON h.category_id = c.id
        LEFT JOIN user_habit_logs uhl ON uh.id = uhl.user_habit_id 
            AND uhl.completed_at::date BETWEEN p_start_date AND p_end_date
        WHERE uh.user_id = p_user_id
        AND uh.is_active = true
        GROUP BY c.id, c.name
        HAVING COUNT(DISTINCT uh.id) > 0
    )
    SELECT category_name
    INTO v_needs_attention_category
    FROM category_performance
    ORDER BY completed_habits ASC, total_habits DESC
    LIMIT 1;
    
    v_needs_attention_category := COALESCE(v_needs_attention_category, 'Todas por igual');
    
    -- RETORNAR RESULTADOS
    RETURN QUERY
    SELECT 'weekly_change'::TEXT, v_weekly_change::TEXT
    UNION ALL
    SELECT 'current_streak'::TEXT, v_current_streak::TEXT
    UNION ALL
    SELECT 'habit_variety'::TEXT, v_habit_variety::TEXT
    UNION ALL
    SELECT 'healthy_adoption_pct'::TEXT, v_healthy_adoption_pct::TEXT
    UNION ALL
    SELECT 'best_adopted_category'::TEXT, v_best_category::TEXT
    UNION ALL
    SELECT 'conversation_insights'::TEXT, v_conversation_insights::TEXT
    UNION ALL
    SELECT 'wellness_score'::TEXT, v_wellness_score::TEXT
    UNION ALL
    SELECT 'needs_attention_category'::TEXT, v_needs_attention_category::TEXT;
    
END;
$$;