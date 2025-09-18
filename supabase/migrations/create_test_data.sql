-- Crear datos de prueba para el usuario si no existen
-- Primero verificar si ya existen datos

DO $$
DECLARE
    user_exists INTEGER;
    test_user_id UUID := '8e622f30-084d-4015-a3b8-6ae33e8ee991'::uuid;
    test_category_id UUID;
    test_habit_id UUID;
BEGIN
    -- Verificar si el usuario ya tiene hábitos
    SELECT COUNT(*) INTO user_exists 
    FROM user_habits 
    WHERE user_id = test_user_id;
    
    RAISE NOTICE 'Usuario tiene % hábitos existentes', user_exists;
    
    -- Si no tiene hábitos, crear datos de prueba
    IF user_exists = 0 THEN
        RAISE NOTICE 'Creando datos de prueba para el usuario';
        
        -- Obtener o crear una categoría de prueba
        SELECT id INTO test_category_id 
        FROM categories 
        WHERE name = 'Salud' 
        LIMIT 1;
        
        IF test_category_id IS NULL THEN
            INSERT INTO categories (name, description, color, icon)
            VALUES ('Salud', 'Hábitos relacionados con la salud', '#4CAF50', 'heart')
            RETURNING id INTO test_category_id;
            RAISE NOTICE 'Categoría creada: %', test_category_id;
        END IF;
        
        -- Obtener o crear un hábito de prueba
        SELECT id INTO test_habit_id 
        FROM habits 
        WHERE name = 'Beber agua' 
        LIMIT 1;
        
        IF test_habit_id IS NULL THEN
            INSERT INTO habits (name, description, category_id, icon_name, icon_color, difficulty_level, estimated_duration)
            VALUES ('Beber agua', 'Beber al menos 8 vasos de agua al día', test_category_id, 'water_drop', '#2196F3', 'easy', 5)
            RETURNING id INTO test_habit_id;
            RAISE NOTICE 'Hábito creado: %', test_habit_id;
        END IF;
        
        -- Crear user_habit de prueba
        INSERT INTO user_habits (
            user_id, 
            habit_id, 
            frequency, 
            scheduled_time, 
            start_date, 
            is_active
        ) VALUES (
            test_user_id,
            test_habit_id,
            'daily',
            '08:00:00'::time,
            CURRENT_DATE,
            true
        );
        
        RAISE NOTICE 'User habit creado para usuario %', test_user_id;
        
        -- Crear otro hábito personalizado
        INSERT INTO user_habits (
            user_id, 
            custom_name, 
            custom_description,
            category_id,
            frequency, 
            scheduled_time, 
            start_date, 
            is_active
        ) VALUES (
            test_user_id,
            'Ejercicio matutino',
            'Hacer 30 minutos de ejercicio cada mañana',
            test_category_id,
            'daily',
            '07:00:00'::time,
            CURRENT_DATE,
            true
        );
        
        RAISE NOTICE 'Hábito personalizado creado';
        
    ELSE
        RAISE NOTICE 'El usuario ya tiene hábitos, no se crean datos de prueba';
    END IF;
END $$;