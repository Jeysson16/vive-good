-- Verificar stored procedures existentes relacionados con habit_suggestions
SELECT 
    proname as function_name,
    pg_get_function_arguments(oid) as arguments,
    pg_get_function_result(oid) as return_type
FROM pg_proc 
WHERE proname LIKE '%habit_suggestions%'
ORDER BY proname;

-- Probar el stored procedure con datos de prueba
SELECT * FROM get_habit_suggestions(
    p_user_id := '00000000-0000-0000-0000-000000000000'::uuid,
    p_category_id := NULL,
    p_limit := 5
);