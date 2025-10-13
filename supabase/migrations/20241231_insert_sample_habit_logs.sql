-- Insertar datos de prueba en habit_logs
-- Estos datos permitirán que las estadísticas muestren información real

-- Primero, obtener algunos IDs de usuarios y hábitos existentes
-- Nota: Estos INSERT usarán datos existentes en la base de datos

-- Insertar registros de hábitos completados para los últimos 30 días
-- Simulando diferentes patrones de completación para generar estadísticas variadas

DO $$
DECLARE
    sample_user_id UUID;
    habit_record RECORD;
    date_offset INTEGER;
    completion_probability FLOAT;
BEGIN
    -- Obtener un usuario de ejemplo (el primero disponible)
    SELECT id INTO sample_user_id FROM auth.users LIMIT 1;
    
    -- Si no hay usuarios, salir
    IF sample_user_id IS NULL THEN
        RAISE NOTICE 'No hay usuarios disponibles para crear datos de prueba';
        RETURN;
    END IF;
    
    -- Para cada hábito existente, crear registros de los últimos 30 días
    FOR habit_record IN 
        SELECT h.id as habit_id, h.name, c.name as category_name
        FROM habits h 
        JOIN categories c ON h.category_id = c.id 
        LIMIT 10
    LOOP
        -- Crear registros para los últimos 30 días
        FOR date_offset IN 0..29 LOOP
            -- Variar la probabilidad de completación según el hábito
            completion_probability := 0.6 + (RANDOM() * 0.3); -- Entre 60% y 90%
            
            -- Solo insertar si el "dado" dice que se completó
            IF RANDOM() < completion_probability THEN
                INSERT INTO public.habit_logs (
                    user_id,
                    habit_id,
                    completion_date,
                    is_completed,
                    notes,
                    created_at
                ) VALUES (
                    sample_user_id,
                    habit_record.habit_id,
                    CURRENT_DATE - date_offset,
                    true,
                    CASE 
                        WHEN RANDOM() < 0.3 THEN 'Completado con éxito'
                        WHEN RANDOM() < 0.6 THEN 'Buen progreso'
                        ELSE NULL
                    END,
                    CURRENT_TIMESTAMP - (date_offset || ' days')::INTERVAL
                ) ON CONFLICT (user_id, habit_id, completion_date) DO NOTHING;
            END IF;
        END LOOP;
        
        RAISE NOTICE 'Creados registros para hábito: %', habit_record.name;
    END LOOP;
    
    RAISE NOTICE 'Datos de prueba insertados correctamente para usuario: %', sample_user_id;
END $$;

-- Insertar algunos registros adicionales para diferentes usuarios si existen
DO $$
DECLARE
    user_recor