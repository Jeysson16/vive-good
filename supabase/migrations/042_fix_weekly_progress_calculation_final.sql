-- Corregir cálculo de progreso semanal para mostrar datos reales en lugar de 0
-- El problema es que el cálculo actual no considera correctamente las completaciones semanales

-- Eliminar función existente
DROP FUNCTION IF EXISTS calculate_user_progress(UUID);

-- Recrear función con lógica corregida para progreso semanal
CREATE OR REPLACE FUNCTION calculate_user_progress(p_user_id UUID)
RETURNS TABLE (
    weekly_completed_habits INTEGER,
    suggested_habits INTEGER,
    pending_activities INTEGER,
    new_habits INTEGER,
    weekly_progress_percentage DECIMAL(5,2),
    accepted_nutrition_suggestions INTEGER,
    current_streak INTEGER
) AS $$
DECLARE
    debug_info TEXT := '';
BEGIN
    -- Log de debugging
    RAISE NOTICE 'calculate_user_progress: Iniciando cálculo para user_id: %', p_user_id;
    
    RETURN QUERY
    WITH date_range AS (
        SELECT 
            CURRENT_DATE - INTERVAL '6 days' as week_start,
            CURRENT_DATE as week_end
    ),
    active_habits AS (
        SELECT 
            uh.id as user_habit_id,
            uh.created_at,
            uh.category_id,
            uh.is_public,
            uh.is_active
        FROM public.user_habits uh
        WHERE uh.user_id = p_user_id 
        AND uh.is_active = true
    ),
    weekly_completions AS (
        SELECT 
            ah.user_habit_id,
            ah.created_at,
            ah.category_id,
            ah.is_public,
            -- Contar completaciones únicas por día en la semana
            COUNT(DISTINCT DATE(uhl.completed_at)) as days_completed_this_week,
            -- Verificar si se completó al menos una vez esta semana
            CASE WHEN COUNT(uhl.id) > 0 THEN 1 ELSE 0 END as completed_this_week,
            -- Verificar si es hábito sugerido
            CASE WHEN ah.is_public = true THEN 1 ELSE 0 END as is_suggested,
            -- Verificar si está pendiente (activo pero no completado hoy)
            CASE WHEN NOT EXISTS(
                SELECT 1 FROM user_habit_logs uhl_today 
                WHERE uhl_today.user_habit_id = ah.user_habit_id 
                AND uhl_today.status = 'completed'
                AND DATE(uhl_today.completed_at) = CURRENT_DATE
            ) THEN 1 ELSE 0 END as is_pending,
            -- Verificar si es hábito de nutrición
            CASE WHEN EXISTS(
                SELECT 1 FROM categories c 
                WHERE c.id = ah.category_id 
                AND (LOWER(c.name) LIKE '%alimentaci%' OR LOWER(c.name) LIKE '%nutrici%' OR LOWER(c.name) LIKE '%comida%')
            ) THEN 1 ELSE 0 END as is_nutrition
        FROM active_habits ah
        LEFT JOIN user_habit_logs uhl ON uhl.user_habit_id = ah.user_habit_id
            AND uhl.status = 'completed'
            AND DATE(uhl.completed_at) BETWEEN (CURRENT_DATE - INTERVAL '6 days') AND CURRENT_DATE
        GROUP BY ah.user_habit_id, ah.created_at, ah.category_id, ah.is_public
    ),
    nutrition_stats AS (
        SELECT 
            COUNT(*) as total_nutrition_habits,
            SUM(wc.completed_this_week) as completed_nutrition_habits
        FROM weekly_completions wc
        WHERE wc.is_nutrition = 1
    ),
    final_stats AS (
        SELECT 
            COALESCE(SUM(wc.completed_this_week)::INTEGER, 0) as weekly_completed_habits,
            COALESCE(SUM(wc.is_suggested)::INTEGER, 0) as suggested_habits,
            COALESCE(SUM(wc.is_pending)::INTEGER, 0) as pending_activities,
            COALESCE(COUNT(CASE WHEN wc.created_at >= CURRENT_DATE - INTERVAL '6 days' THEN 1 END)::INTEGER, 0) as new_habits,
            -- Calcular porcentaje basado en hábitos completados vs total de hábitos activos
            CASE 
                WHEN COUNT(*) > 0 THEN 
                    LEAST(100.0, GREATEST(0.0, 
                        ROUND((SUM(wc.completed_this_week)::DECIMAL / COUNT(*)::DECIMAL) * 100, 2)
                    ))
                ELSE 0.0
            END as weekly_progress_percentage,
            -- Calcular sugerencias de nutrición aceptadas
            CASE 
                WHEN ns.total_nutrition_habits > 0 THEN 
                    LEAST(100, GREATEST(0, 
                        ROUND((ns.completed_nutrition_habits::DECIMAL / ns.total_nutrition_habits::DECIMAL) * 100)
                    ))
                ELSE 0
            END::INTEGER as accepted_nutrition_suggestions,
            -- Calcular racha actual
            calculate_user_streak(p_user_id) as current_streak,
            -- Datos para debugging
            COUNT(*) as total_active_habits,
            SUM(wc.completed_this_week) as total_completed_this_week
        FROM weekly_completions wc
        CROSS JOIN nutrition_stats ns
    )
    SELECT 
        fs.weekly_completed_habits,
        fs.suggested_habits,
        fs.pending_activities,
        fs.new_habits,
        fs.weekly_progress_percentage,
        fs.accepted_nutrition_suggestions,
        fs.current_streak
    FROM final_stats fs;
    
    -- Log de debugging con resultados
    RAISE NOTICE 'calculate_user_progress: Completado para user_id: %', p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Otorgar permisos
GRANT EXECUTE ON FUNCTION calculate_user_progress(UUID) TO anon;
GRANT EXECUTE ON FUNCTION calculate_user_progress(UUID) TO authenticated;

-- Comentario
COMMENT ON FUNCTION calculate_user_progress(UUID) IS 'Calcula métricas de progreso del usuario con lógica corregida para progreso semanal real';