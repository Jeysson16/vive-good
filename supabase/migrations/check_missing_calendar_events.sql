-- Consulta para verificar hábitos sin eventos de calendario
-- Esta consulta identifica user_habits que no tienen eventos correspondientes en calendar_events

SELECT 
    uh.id as user_habit_id,
    uh.user_id,
    uh.habit_id,
    h.name as habit_name,
    uh.start_date,
    uh.end_date,
    uh.frequency,
    uh.scheduled_time,
    uh.created_at,
    COUNT(ce.id) as calendar_events_count
FROM user_habits uh
LEFT JOIN habits h ON uh.habit_id = h.id
LEFT JOIN calendar_events ce ON uh.habit_id = ce.habit_id AND uh.user_id = ce.user_id
WHERE uh.is_active = true
GROUP BY uh.id, uh.user_id, uh.habit_id, h.name, uh.start_date, uh.end_date, uh.frequency, uh.scheduled_time, uh.created_at
ORDER BY uh.created_at DESC;

-- Consulta adicional para ver todos los eventos de calendario existentes
SELECT 
    ce.id,
    ce.user_id,
    ce.habit_id,
    ce.title,
    ce.start_date,
    ce.start_time,
    ce.recurrence_type,
    ce.is_completed,
    ce.created_at
FROM calendar_events ce
ORDER BY ce.created_at DESC
LIMIT 20;

-- Consulta para verificar user_habits activos
SELECT 
    uh.id,
    uh.user_id,
    uh.habit_id,
    h.name as habit_name,
    uh.start_date,
    uh.frequency,
    uh.is_active,
    uh.created_at
FROM user_habits uh
LEFT JOIN habits h ON uh.habit_id = h.id
WHERE uh.is_active = true
ORDER BY uh.created_at DESC
LIMIT 10;