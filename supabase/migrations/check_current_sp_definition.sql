-- Verificar la definición actual del stored procedure get_dashboard_habits
SELECT 
    proname as function_name,
    pg_get_function_arguments(oid) as arguments,
    pg_get_function_result(oid) as return_type,
    prosrc as source_code
FROM pg_proc 
WHERE proname = 'get_dashboard_habits'
ORDER BY oid DESC
LIMIT 1;

-- También verificar si hay múltiples versiones
SELECT 
    proname as function_name,
    oid,
    proargnames as argument_names,
    proargtypes as argument_types
FROM pg_proc 
WHERE proname = 'get_dashboard_habits';