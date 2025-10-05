-- Script para probar la sincronización de hábitos con calendario
-- Verificar hábitos existentes
SELECT 
    uh.id,
    uh.user_id,
    uh.habit_id,
    COALESCE(uh.custom_name, h.name) as habit_name,
    uh.frequency,
    uh.start_date,
    uh.end_date,
    uh.is_active,
    uh.created_at
FROM user_habits uh
LEFT JOIN habits h ON uh.habit_id = h.id
WHERE uh.is_active = true
ORDER BY uh.created_at DESC
LIMIT 10;

-- Verificar eventos de calendario existentes
SELECT 
    ce.id,
    ce.user_id,
    ce.habit_id,
    ce.title,
    ce.start_date,
    ce.start_time,
    ce.end_time,
    ce.recurrence_type,
    ce.is_completed,
    ce.created_at
FROM calendar_events ce
ORDER BY ce.created_at DESC
LIMIT 10;

-- Verificar hábitos sin eventos de calendario usando la función creada
SELECT * FROM get_habits_without_calendar_events('f47ac10b-58cc-4372-a567-0e02b2c3d479');

-- Contar hábitos vs eventos por usuario
SELECT 
    u.id as user_id,
    u.email,
    COUNT(DISTINCT uh.id) as total_habits,
    COUNT(DISTINCT ce.id) as total_calendar_events
FROM auth.users u
LEFT JOIN user_habits uh ON u.id = uh.user_id AND uh.is_active = true
LEFT JOIN calendar_events ce ON u.id = ce.user_id
GROUP BY u.id, u.email
ORDER BY total_habits DESC;