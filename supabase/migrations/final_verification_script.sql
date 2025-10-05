-- Script de verificación final para confirmar que el problema está solucionado
-- Este script ejecuta todas las verificaciones necesarias

-- 1. Verificar duplicados existentes
SELECT 'PASO 1: Verificando duplicados existentes' as paso;
SELECT * FROM check_duplicate_user_habits() LIMIT 5;

-- 2. Ejecutar pruebas de sugerencias automáticas
SELECT 'PASO 2: Ejecutando pruebas automáticas de sugerencias' as paso;
SELECT * FROM run_automatic_habit_suggestions_test();

-- 3. Verificar estadísticas generales
SELECT 'PASO 3: Estadísticas generales del sistema' as paso;

SELECT 
    'Total usuarios con hábitos activos' as metrica,
    COUNT(DISTINCT user_id) as valor
FROM user_habits 
WHERE is_active = true;

SELECT 
    'Total hábitos únicos en biblioteca' as metrica,
    COUNT(*) as valor
FROM habits 
WHERE is_active = true;

SELECT 
    'Total relaciones usuario-hábito activas' as metrica,
    COUNT(*) as valor
FROM user_habits 
WHERE is_active = true;

-- 4. Prueba manual con un usuario específico
SELECT 'PASO 4: Ejemplo práctico con usuario real' as paso;

WITH sample_user AS (
    SELECT user_id 
    FROM user_habits 
    WHERE is_active = true 
    LIMIT 1
),
user_habits_list AS (
    SELECT 
        h.id,
        h.name,
        'USUARIO_YA_TIENE' as tipo
    FROM sample_user su
    JOIN user_habits uh ON uh.user_id = su.user_id AND uh.is_active = true
    JOIN habits h ON h.id = uh.habit_id
),
suggestions_list AS (
    SELECT 
        s.id,
        s.name,
        'SUGERENCIA' as tipo
    FROM sample_user su
    CROSS JOIN get_popular_habit_suggestions(su.user_id, NULL, 10) s
)
SELECT * FROM user_habits_list
UNION ALL
SELECT * FROM suggestions_list
ORDER BY tipo, name;

-- 5. Verificar que no hay solapamiento
SELECT 'PASO 5: Verificación de solapamiento (debe ser 0)' as paso;

WITH sample_user AS (
    SELECT user_id 
    FROM user_habits 
    WHERE is_active = true 
    LIMIT 1
),
user_existing_habits AS (
    SELECT DISTINCT habit_id 
    FROM user_habits uh, sample_user su
    WHERE uh.user_id = su.user_id
),
suggested_habits AS (
    SELECT s.id
    FROM sample_user su
    CROSS JOIN get_popular_habit_suggestions(su.user_id, NULL, 20) s
)
SELECT 
    COUNT(*) as solapamiento_count,
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ CORRECTO: No hay solapamiento'
        ELSE '❌ ERROR: Hay hábitos duplicados en sugerencias'
    END as resultado
FROM suggested_habits sh
INNER JOIN user_existing_habits ueh ON sh.id = ueh.habit_id;