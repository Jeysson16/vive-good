-- Verificar qué funciones existen en la base de datos
SELECT 
    routine_name,
    routine_type,
    data_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%progress%'
ORDER BY routine_name;
