-- Script para corregir hábitos sin scheduled_time
-- Actualizar hábitos que tienen notification_time pero no scheduled_time

-- Paso 1: Ver el estado actual
SELECT 
    COUNT(*) as total_habitos,
    COUNT(scheduled_time) as con_scheduled_time,
    COUNT(notification_time) as con_notification_time,
    COUNT(CASE WHEN scheduled_time IS NULL AND notification_time IS NOT NULL THEN 1 END) as sin_scheduled_con_notification
FROM user_habits 
WHERE is_active = true;

-- Paso 2: Actualizar hábitos que tienen notification_time pero no scheduled_time
UPDATE user_habits 
SET scheduled_time = notification_time
WHERE is_active = true 
    AND scheduled_time IS NULL 
    AND notification_time IS NOT NULL;

-- Paso 3: Para hábitos que no tienen scheduled_time, asignar hora por defecto (9:00 AM)
UPDATE user_habits 
SET scheduled_time = '09:00:00'
WHERE is_active = true 
    AND scheduled_time IS NULL;

-- Paso 4: Para hábitos que no tienen notification_time, usar el scheduled_time
UPDATE user_habits 
SET notification_time = scheduled_time
WHERE is_active = true 
    AND notification_time IS NULL 
    AND scheduled_time IS NOT NULL;

-- Paso 5: Verificar el resultado
SELECT 
    COUNT(*) as total_habitos_activos,
    COUNT(scheduled_time) as habitos_con_scheduled_time,
    COUNT(*) - COUNT(scheduled_time) as habitos_sin_scheduled_time,
    ROUND(
        (COUNT(scheduled_time)::decimal / COUNT(*)::decimal) * 100, 2
    ) as porcentaje_con_scheduled_time
FROM user_habits 
WHERE is_active = true;

-- Paso 6: Ver algunos ejemplos de los hábitos actualizados
SELECT 
    uh.id,
    COALESCE(uh.custom_name, h.name) as habit_name,
    c.name as category_name,
    uh.scheduled_time,
    uh.notification_time,
    uh.frequency
FROM user_habits uh
LEFT JOIN habits h ON uh.habit_id = h.id
LEFT JOIN categories c ON h.category_id = c.id
WHERE uh.is_active = true
ORDER BY uh.scheduled_time
LIMIT 10;