-- Script de verificación final para confirmar que el problema está solucionado

-- 1. Verificar duplicados existentes
SELECT 'STEP 1: Verificando duplicados existentes' as step;
SELECT * FROM check_duplicate_user_habits();

-- 2. Ejecutar pruebas de sugerencias
SELECT 'STEP 2: Ejecutando pruebas de sugerencias' as step;
SELECT * FROM run_habit_suggestions_test();

-- 3. Verificar manualmente con un usuario específico (reemplazar UUID)
SELECT 'STEP 3: Verificación manual (reemplazar UUID)' as step;
-- SELECT * FROM test_habit_suggestions_exclusion('REEMPLAZAR-CON-UUID-REAL');

-- 4. Mostrar estadísticas generales
SELECT 'STEP 4: Estadísticas generales' as step;
SELECT 
    'Total usuarios con hábitos' as metric,
    COUNT(DISTINCT user_id) as value
FROM user_habits 
WHERE is_active = true;

SELECT 
    'Total hábitos únicos en biblioteca' as metric,
    COUNT(*) as value
FROM habits 
WHERE is_active = true;

SELECT 
    'Total relaciones usuario-hábito activas' as metric,
    COUNT(*) as value
FROM user_habits 
WHERE is_active = true;

-- 5. Ejemplo de sugerencias para un usuario (sin UUID específico)
SELECT 'STEP 5: Ejemplo de sugerencias' as step;
WITH sample_user AS (
    SELECT user_id 
    FROM user_habits 
    WHERE is_active = true 
    LIMIT 1
)
SELECT 
    h.id,
    h.name,
    h.category_id,
    'SUGERENCIA' as type
FROM sample_user su
CROSS JOIN get_popular_habit_suggestions(su.user_id, NULL, 5) h
UNION ALL
SELECT 
    uh.habit_id as id,
    h.name,
    h.category_id,
    'YA_TIENE' as type
FROM sample_user su
JOIN user_habits uh ON uh.user_id = su.user_id AND uh.is_active = true
JOIN habits h ON h.id = uh.habit_id
ORDER BY type, name