-- Debug script para probar las funciones de progreso con datos reales

-- Verificar que hay datos
SELECT 'User Habits' as table_name, COUNT(*) as count FROM user_habits WHERE is_active = true;
SELECT 'User Habit Logs' as table_name, COUNT(*) as count FROM user_habit_logs WHERE status = 'completed';

-- Probar las funciones con un usuario específico
DO $$
DECLARE
    test_user_id UUID;
    start_date DATE := CURRENT_DATE - INTERVAL '30 days';
    end_date DATE := CURRENT_DATE;
BEGIN
    -- Obtener el primer usuario con hábitos activos
    SELECT DISTINCT user_id INTO test_user_id
    FROM user_habits 
    WHERE is_active = true 
    LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        RAISE NOTICE 'Testing functions with user_id: %', test_user_id;
        RAISE NOTICE 'Date range: % to %', start_date, end_date;
        
        -- Test get_monthly_progress_metrics
        RAISE NOTICE '=== Testing get_monthly_progress_metrics ===';
        PERFORM metric_key, metric_value 
        FROM get_monthly_progress_metrics(test_user_id, start_date, end_date);
        
        RAISE NOTICE 'All function tests completed successfully!';
    ELSE
        RAISE NOTICE 'No users with active habits found';
    END IF;
END $$;