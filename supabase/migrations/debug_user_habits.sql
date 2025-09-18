-- Debug: Verificar datos del usuario específico
-- Consulta 1: Ver todos los user_habits del usuario
DO $$
DECLARE
    rec RECORD;
BEGIN
    RAISE NOTICE 'USER_HABITS para usuario 8e622f30-084d-4015-a3b8-6ae33e8ee991:';
    
    FOR rec IN 
        SELECT 
            uh.id,
            uh.user_id,
            uh.habit_id,
            uh.custom_name,
            uh.start_date,
            uh.end_date,
            uh.is_active,
            uh.frequency,
            h.name as habit_name
        FROM user_habits uh
        LEFT JOIN habits h ON uh.habit_id = h.id
        WHERE uh.user_id = '8e622f30-084d-4015-a3b8-6ae33e8ee991'::uuid
    LOOP
        RAISE NOTICE 'ID: %, Habit: %, Custom: %, Start: %, End: %, Active: %, Freq: %', 
            rec.id, rec.habit_name, rec.custom_name, rec.start_date, rec.end_date, rec.is_active, rec.frequency;
    END LOOP;
    
    RAISE NOTICE 'CALENDAR_EVENTS para usuario 8e622f30-084d-4015-a3b8-6ae33e8ee991:';
    
    FOR rec IN 
        SELECT 
            ce.id,
            ce.user_id,
            ce.habit_id,
            ce.title,
            ce.start_date,
            ce.end_date,
            ce.recurrence_type
        FROM calendar_events ce
        WHERE ce.user_id = '8e622f30-084d-4015-a3b8-6ae33e8ee991'::uuid
    LOOP
        RAISE NOTICE 'Event ID: %, Habit ID: %, Title: %, Start: %, End: %, Recurrence: %', 
            rec.id, rec.habit_id, rec.title, rec.start_date, rec.end_date, rec.recurrence_type;
    END LOOP;
    
    RAISE NOTICE 'Fecha actual: %', CURRENT_DATE;
END $$;