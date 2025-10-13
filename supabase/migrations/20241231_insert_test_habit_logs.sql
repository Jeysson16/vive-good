-- Insertar datos de prueba en user_habit_logs para testing
-- Esto permitirá que las funciones de estadísticas muestren datos

-- Primero, obtener algunos user_habits existentes para crear logs
DO $$
DECLARE
    user_habit_record RECORD;
    test_date DATE;
    i INTEGER;
BEGIN
    -- Crear logs para los últimos 30 días para cada user_habit activo
    FOR user_habit_record IN 
        SELECT uh.id as user_habit_id, uh.user_id, h.name as habit_name
        FROM user_habits uh
        JOIN habits h ON h.id = uh.habit_id
        WHERE uh.is_active = true
        LIMIT 10 -- Limitar a 10 hábitos para no sobrecargar
    LOOP
        -- Crear logs para los últimos 30 días
        FOR i IN 0..29 LOOP
            test_date := CURRENT_DATE - INTERVAL '1 day' * i;
            
            -- Insertar log con probabilidad del 70% de estar completado
            IF RANDOM() < 0.7 THEN
                INSERT INTO user_habit_logs (
                    user_habit_id,
                    completed_at,
                    status,
                    notes,
                    created_at
                ) VALUES (
                    user_habit_record.user_habit_id,
                    test_date + INTERVAL '8 hours' + (RANDOM() * INTERVAL '12 hours'),
                    'completed',
                    'Completado automáticamente - datos de prueba',
                    test_date + INTERVAL '8 hours' + (RANDOM() * INTERVAL '12 hours')
                )
                ON CONFLICT DO NOTHING; -- Evitar duplicados si ya existen
            ELSE
                -- Algunos logs como pendientes o fallidos
                IF RANDOM() < 0.5 THEN
                    INSERT INTO user_habit_logs (
                        user_habit_id,
                        completed_at,
                        status,
                        notes,
                        created_at
                    ) VALUES (
                        user_habit_record.user_habit_id,
                        test_date + INTERVAL '20 hours',
                        'pending',
                        'Pendiente - datos de prueba',
                        test_date + INTERVAL '20 hours'
                    )
                    ON CONFLICT DO NOTHING;
                END IF;
            END IF;
        END LOOP;
        
        RAISE NOTICE 'Creados logs para hábito: %', user_habit_record.habit_name;
    END LOOP;
    
    RAISE NOTICE 'Datos de prueba insertados exitosamente en user_habit_logs';
END $$;