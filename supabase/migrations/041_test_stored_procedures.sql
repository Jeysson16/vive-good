-- Test para verificar que los stored procedures existen y funcionan
-- Este archivo verifica que las funciones corregidas estén disponibles

-- Test 1: Verificar que get_monthly_progress_metrics existe
SELECT 'Testing get_monthly_progress_metrics...' as test_name;
SELECT * FROM get_monthly_progress_metrics('8e622f30-084d-4015-a3b8-6ae33e8ee991'::uuid, '2025-10-01'::date, '2025-10-31'::date) LIMIT 5;

-- Test 2: Verificar que get_category_progress_metrics existe
SELECT 'Testing get_category_progress_metrics...' as test_name;
SELECT * FROM get_category_progress_metrics('8e622f30-084d-4015-a3b8-6ae33e8ee991'::uuid, '2025-10-01'::date, '2025-10-31'::date) LIMIT 5;

-- Test 3: Verificar que get_weekly_trend_metrics existe
SELECT 'Testing get_weekly_trend_metrics...' as test_name;
SELECT * FROM get_weekly_trend_metrics('8e622f30-084d-4015-a3b8-6ae33e8ee991'::uuid) LIMIT 5;

-- Test 4: Verificar que get_temporal_analysis_metrics existe
SELECT 'Testing get_temporal_analysis_metrics...' as test_name;
SELECT * FROM get_temporal_analysis_metrics('8e622f30-084d-4015-a3b8-6ae33e8ee991'::uuid, '2025-10-01'::date, '2025-10-31'::date) LIMIT 5;