-- Script para probar sincronización manual de hábitos
-- Paso 1: Obtener un usuario con hábitos activos
SELECT 
    uh.user_id,
    u.email,
    COUNT(*) as total_habitos,
    COUNT(uh.scheduled_time) as habitos_con_hora,
    STRING_AGG(
        COALESCE(uh.custom_name, h.name) || ' (' || 
        COALESCE(uh.scheduled_time::text, 'SIN HORA') || ')', 
        ', '
    ) as lista_habitos
FROM user_habits uh
LEFT JOIN habits h ON uh.habit_id = h.id
LEFT JOIN auth.users u ON uh.user_id = u.id
WHERE uh.is_active = true
GROUP BY uh.user_id, u.email
HAVING COUNT(*) > 0
ORDER BY total_habitos DESC
LIMIT 5;

-- Paso 2: Verificar hábitos sin eventos de calendario para un usuario específico
-- (Reemplazar USER_ID_AQUI con un ID real del resultado anterior)
SELECT 
    uh.id as user_habit_id,
    uh.user_id,
    COALESCE(uh.custom_name, h.name) as habit_name,
    uh.frequency,
    uh.scheduled_time,
    uh.start_date,
    COUNT(ce.id) as eventos_existentes
FROM user_habits uh
LEFT JOIN habits h ON uh.habit_id = h.id
LEFT JOIN calendar_events ce ON uh.id = ce.habit_id AND ce.user_id = uh.user_id
WHERE uh.is_active = true 
    AND uh.user_id = (
        SELECT user_id 
        FROM user_habits 
        WHERE is_active = true 
        GROUP BY user_id 
        ORDER BY COUNT(*) DESC 
        LIMIT 1
    )
GROUP BY uh.id, uh.user_id, h.name, uh.custom_name, uh.frequency, uh.scheduled_time, uh.start_date
ORDER BY uh.scheduled_time NULLS LAST;

-- Paso 3: Llamar a la función de sincronización para el usuario
-- (Esta función debería crear eventos de calendario para hábitos sin eventos)
DO $$
DECLARE
    target_user_id UUID;
    sync_result TEXT;
BEGIN
    -- Obtener el usuario con más hábitos
    SELECT user_id INTO target_user_id
    FROM user_habits 
    WHERE is_active = true 
    GROUP BY user_id 
    ORDER BY COUNT(*) DESC 
    LIMIT 1;
    
    -- Mostrar información del usuario
    RAISE NOTICE 'Sincronizando hábitos para usuario: %', target_user_id;
    
    -- Llamar a la función de sincronización si existe
    -- (Nota: Esta función puede no existir aún, es solo para prueba)
    -- SELECT sync_user_habits_to_calendar(target_user_id) INTO sync_result;
    -- RAISE NOTICE 'Resultado de sincronización: %', sync_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error en sincronización: %', SQLERRM;
END $$;

-- Paso 4: Verificar eventos creados después de la sincronización
SELECT 
    ce.id,
    ce.user_id,
    ce.habit_id,
    ce.title,
    ce.start_date,
    ce.start_time,
    ce.end_time,
    ce.recurrence_type,
    uh.scheduled_time as hora_programada_habito,
    CASE 
        WHEN ce.start_time = uh.scheduled_time THEN 'HORA CORRECTA'
        WHEN uh.scheduled_time IS NULL THEN 'HABITO SIN HORA'
        ELSE 'HORA INCORRECTA'
    END as verificacion_hora
FROM calendar_events ce
LEFT JOIN user_habits uh ON ce.habit_id = uh.id
WHERE ce.user_id = (
    SELECT user_id 
    FROM user_habits 
    WHERE is_active = true 
    GROUP BY user_id 
    ORDER BY COUNT(*) DESC 
    LIMIT 1
)
ORDER BY ce.start_date, ce.start_time;