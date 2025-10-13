-- Probar las funciones con datos reales para verificar que devuelvan información correcta

DO $$
DECLARE
    test_user_id UUID;
    v_start_date DATE := CURRENT_DATE - INTERVAL '30 days';
    v_end_date DATE := CURRENT_DATE;
    result_record RECORD;
    result_count INTEGER := 0;
BEGIN
    -- Obtener el primer usuario con hábitos activos
    SELECT DISTINCT user_id INTO test_user_id
    FROM user_habits 
    WHERE is_active = true 
    LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        RAISE NOTICE 'Testing functions with user_id: %', test_user_id;
        RAISE NOTICE 'Date range: % to %', v_start_date, v_end_date;
        
        -- Verificar datos básicos
        SELECT COUNT(*) INTO result_count FROM user_habits WHERE user_id = test_user_id AND is_active = true;
        RAISE NOTICE 'Active habits for user: %', result_count;
        
        SELECT COUNT(*) INTO result_count FROM user_habit_logs uhl 
        JOIN user_habits uh ON uh.id = uhl.user_habit_id 
        WHERE uh.user_id = test_user_id AND uhl.status = 'completed' 
        AND uhl.completed_at::date BETWEEN v_start_date AND v_end_date;
        RAISE NOTICE 'Completed habits in date range: %', result_count;
        
        -- Test get_monthly_progress_metrics
        RAISE NOTICE '=== Testing get_monthly_progress_metrics ===';
        result_count := 0;
        FOR result_record IN 
            SELECT metric_key, metric_value 
            FROM get_monthly_progress_metrics(test_user_id, v_start_date, v_end_date)
        LOOP
            result_count := result_count + 1;
            RAISE NOTICE 'Metric: % = %', result_record.metric_key, result_record.metric_value;
        END LOOP;
        RAISE NOTICE 'get_monthly_progress_metrics returned % rows', result_count;
        
        -- Test get_category_evolution
        RAISE NOTICE '=== Testing get_category_evolution ===';
        result_count := 0;
        FOR result_record IN 
            SELECT category_name, monthly_average 
            FROM get_category_evolution(test_user_id, EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER, EXTRACT(MONTH FROM CURRENT_DATE)::INTEGER)
        LOOP
            result_count := result_count + 1;
            RAISE NOTICE 'Category: % = %', result_record.category_name, result_record.monthly_average;
        END LOOP;
        RAISE NOTICE 'get_category_evolution returned % rows', result_count;
        
        -- Test get_temporal_analysis_metrics
        RAISE NOTICE '=== Testing get_temporal_analysis_metrics ===';
        result_count := 0;
        FOR result_record IN 
            SELECT metric_key, metric_value 
            FROM get_temporal_analysis_metrics(test_user_id, v_start_date, v_end_date)
        LOOP
            result_count := result_count + 1;
            RAISE NOTICE 'Temporal metric: % = %', result_record.metric_key, result_record.metric_value;
        END LOOP;
        RAISE NOTICE 'get_temporal_analysis_metrics returned % rows', result_count;
        
        RAISE NOTICE 'All function tests completed successfully!';
    ELSE
        RAISE NOTICE 'No users with active habits found';
    END IF;
END $$;