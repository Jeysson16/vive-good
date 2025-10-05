-- Verificar horarios programados en user_habits
-- Consulta 1: Ver todos los hábitos activos con sus horarios
SELECT 
    uh.id as user_habit_id,
    uh.user_id,
    uh.habit_id,
    COALESCE(uh.custom_name, h.name) as habit_name,
    uh.frequency,
    uh.scheduled_time,
    uh.start_date,
    uh.is_active,
    uh.created_at,
    CASE 
        WHEN uh.scheduled_time IS NULL THEN 'SIN HORA'
        ELSE 'CON HORA: ' || uh.scheduled_time::text
    END as status_hora
FROM user_habits uh
LEFT JOIN habits h ON uh.habit_id = h.id
WHERE uh.is_active = true
ORDER BY uh.user_id, uh.scheduled_time NULLS LAST;

-- Consulta 2: Estadísticas de horarios programados
SELECT 
    COUNT(*) as total_habitos_activos,
    COUNT(scheduled_time) as habitos_con_hora,
    COUNT(*) - COUNT(scheduled_time) as habitos_sin_hora,
    ROUND(
        (COUNT(scheduled_time)::decimal / COUNT(*)::decimal) * 100, 2
    ) as porcentaje_con_hora
FROM user_habits 
WHERE is_active = true;

-- Consulta 3: Distribución de horarios por usuario
SELECT 
    uh.user_id,
    u.email,
    COUNT(*) as total_habitos,
    COUNT(uh.scheduled_time) as habitos_con_hora,
    COUNT(*) - COUNT(uh.scheduled_time) as habitos_sin_hora
FROM user_habits uh
LEFT JOIN auth.users u ON uh.user_id = u.id
WHERE uh.is_active = true
GROUP BY uh.user_id, u.email
ORDER BY total_habitos DESC;

-- Consulta 4: Ver eventos de calendario existentes con sus horarios
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
ORDER BY ce.user_id, ce.start_date, ce.start_time
LIMIT 20;