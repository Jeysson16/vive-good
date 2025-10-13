-- Verificar que las funciones existen en la base de datos
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%progress%' 
OR routine_name LIKE '%temporal%'
ORDER BY routine_name;