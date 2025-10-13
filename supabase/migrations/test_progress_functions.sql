-- Test script para verificar que las funciones de progreso devuelvan datos correctos
-- Este script se puede ejecutar para probar las funciones con un usuario específico

-- Función de prueba para verificar get_monthly_progress_metrics
DO $$
DECLARE
    test_user_id UUID;
    result_count INTEGER;
BEGIN
    -- Obtener un usuario que tenga hábitos
    SELECT DISTINCT uh.user_id INTO test_user_id
    FROM user_habits uh
    WHERE uh.is_active = true
    LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        RAISE NOTICE 'Testing with user_id: %', test_user_id;
        
        -- Test get_monthly_progress_metrics
        SELECT COUNT(*) INTO result_count
        FROM get_monthly_progress_metrics(test_user_id, CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE);
        RAISE NOTICE 'get_monthly_progress_metrics returned % rows', result_count;
        
        -- Test get_category_progress_metrics
        SELECT COUNT(*) INTO result_count
        FROM get_category_progress_metrics(test_user_id, CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE);
        RAISE NOTICE 'get_category_progress_metrics returned % rows', result_count;
        
        -- Test get_weekly_trend_metrics
        SELECT COUNT(*) INTO result_count
        FROM get_weekly_trend_metrics(test_user_id);
        RAISE NOTICE 'get_weekly_trend_metrics returned % rows', result_count;
        
        -- Test get_temporal_analysis_metrics
        SELECT COUNT(*) INTO result_count
        FROM get_temporal_analysis_metrics(test_user_id, CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE);
        RAISE NOTICE 'get_temporal_analysis_metrics returned % rows', result_count;
        
    ELSE
        RAISE NOTICE 'No active user habits found for testing';
    END IF;
END $$;

-- Mostrar algunos datos de ejemplo para verificar
SELECT 'User Habits Count' as info, COUNT(*) as count FROM user_habits WHERE is_active = true;
SELECT 'User Habit Logs Count' as info, COUNT(*) as count FROM user_habit_logs WHERE status = 'completed';
SELECT 'Recent Logs' as info, COUNT(*) as count FROM user_habit_logs WHERE completed_at >= CURRENT_DATE - INTERVAL '30 days';