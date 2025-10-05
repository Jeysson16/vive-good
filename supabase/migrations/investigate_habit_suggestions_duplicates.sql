-- Script para investigar datos duplicados en user_habits
-- Este script identifica posibles duplicados que podrían estar causando
-- que las sugerencias de hábitos devuelvan hábitos ya existentes

-- 1. Verificar duplicados exactos (mismo user_id y habit_id)
SELECT 
    'DUPLICADOS EXACTOS' as tipo_consulta,
    user_id,
    habit_id,
    COUNT(*) as duplicate_count,
    STRING_AGG(id::text, ', ') as duplicate_ids,
    STRING_AGG(is_active::text, ', ') as active_status,
    STRING_AGG(created_at::text, ', ') as created_dates
FROM user_habits 
GROUP BY user_id, habit_id 
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 2. Verificar hábitos activos duplicados (más crítico)
SELECT 
    'DUPLICADOS ACTIVOS' as tipo_consulta,
    user_id,
    habit_id,
    COUNT(*) as active_duplicate_count,
    STRING_AGG(id::text, ', ') as duplicate_ids
FROM user_habits 
WHERE is_active = true
GROUP BY user_id, habit_id 
HAVING COUNT(*) > 1
ORDER BY active_duplicate_count DESC;

-- 3. Verificar inconsistencias en el estado is_active para el mismo hábito
SELECT 
    'INCONSISTENCIAS ESTADO' as tipo_consulta,
    uh.user_id,
    uh.habit_id,
    h.name as habit_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN uh.is_active = true THEN 1 END) as active_count,
    COUNT(CASE WHEN uh.is_active = false THEN 1 END) as inactive_count,
    STRING_AGG(uh.id::text || ':' || uh.is_active::text, ', ') as records_detail
FROM user_habits uh
JOIN habits h ON h.id = uh.habit_id
GROUP BY uh.user_id, uh.habit_id, h.name
HAVING COUNT(*) > 1
ORDER BY total_records DESC;

-- 4. Verificar el total de hábitos por usuario para detectar anomalías
SELECT 
    'ESTADISTICAS USUARIO' as tipo_consulta,
    user_id,
    COUNT(*) as total_habits,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_habits,
    COUNT(CASE WHEN is_active = false THEN 1 END) as inactive_habits
FROM user_habits 
GROUP BY user_id 
ORDER BY total_habits DESC
LIMIT 10;

-- 5. Verificar si hay hábitos que aparecen en sugerencias pero ya están en user_habits
-- (Simulando la lógica del stored procedure problemático)
WITH sample_user AS (
    SELECT user_id 
    FROM user_habits 
    WHERE is_active = true 
    LIMIT 1
),
user_existing_habits AS (
    SELECT DISTINCT uh.habit_id 
    FROM user_habits uh, sample_user su
    WHERE uh.user_id = su.user_id
    AND uh.is_active = true
),
suggested_habits AS (
    SELECT h.id, h.name, h.category_id
    FROM habits h
    WHERE h.is_active = true
    ORDER BY h.popularity_score DESC NULLS LAST, h.name
    LIMIT 20
)
SELECT 
    'VERIFICACION SUGERENCIAS' as tipo_consulta,
    sh.id,
    sh.name,
    sh.category_id,
    CASE WHEN ueh.habit_id IS NOT NULL THEN 'YA_EXISTE' ELSE 'NUEVA_SUGERENCIA' END as status
FROM suggested_habits sh
LEFT JOIN user_existing_habits ueh ON sh.id = ueh.habit_id
ORDER BY status, sh.name;