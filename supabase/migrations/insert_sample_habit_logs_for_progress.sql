-- Insertar logs de hábitos de ejemplo para mostrar progreso en la interfaz de perfil
-- Esto creará logs para la semana actual para demostrar el progreso dinámico

-- Primero, verificar si el usuario tiene hábitos activos
DO $$
DECLARE
    current_user_id UUID;
    hydration_habit_id UUID;
    sleep_habit_id UUID;
    activity_habit_id UUID;
    current_week_start DATE;
BEGIN
    -- Obtener el ID del usuario actual (Jeysson Manuel)
    SELECT id INTO current_user_id 
    FROM profiles 
    WHERE first_name = 'Jeysson Manuel' AND last_name = 'Sánchez Rodríguez'
    LIMIT 1;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE 'Usuario no encontrado';
        RETURN;
    END IF;
    
    -- Calcular el inicio de la semana actual
    current_week_start := DATE_TRUNC('week', CURRENT_DATE);
    
    -- Buscar hábitos relacionados con hidratación
    SELECT uh.id INTO hydration_habit_id
    FROM user_habits uh
    INNER JOIN habits h ON h.id = uh.habit_id
    INNER JOIN categories c ON c.id = h.category_id
    WHERE uh.user_id = current_user_id 
    AND uh.is_active = true
    AND (LOWER(h.name) LIKE '%agua%' OR LOWER(h.name) LIKE '%hidrat%' OR LOWER(c.name) LIKE '%hidrat%')
    LIMIT 1;
    
    -- Buscar hábitos relacionados con sueño
    SELECT uh.id INTO sleep_habit_id
    FROM user_habits uh
    INNER JOIN habits h ON h.id = uh.habit_id
    INNER JOIN categories c ON c.id = h.category_id
    WHERE uh.user_id = current_user_id 
    AND uh.is_active = true
    AND (LOWER(h.name) LIKE '%sueño%' OR LOWER(h.name) LIKE '%dormir%' OR LOWER(c.name) LIKE '%sueño%')
    LIMIT 1;
    
    -- Buscar hábitos relacionados con actividad
    SELECT uh.id INTO activity_habit_id
    FROM user_habits uh
    INNER JOIN habits h ON h.id = uh.habit_id
    INNER JOIN categories c ON c.id = h.category_id
    WHERE uh.user_id = current_user_id 
    AND uh.is_active = true
    AND (LOWER(h.name) LIKE '%ejercicio%' OR LOWER(h.name) LIKE '%actividad%' OR LOWER(c.name) LIKE '%ejercicio%' OR LOWER(c.name) LIKE '%actividad%')
    LIMIT 1;
    
    -- Insertar logs de hidratación (3 días de la semana)
    IF hydration_habit_id IS NOT NULL THEN
        -- Lunes
        INSERT INTO user_habit_logs (user_habit_id, status, completed_at, created_at, updated_at)
        VALUES (hydration_habit_id, 'completed', current_week_start + INTERVAL '10 hours', NOW(), NOW())
        ON CONFLICT DO NOTHING;
        
        -- Martes
        INSERT INTO user_habit_logs (user_habit_id, status, completed_at, created_at, updated_at)
        VALUES (hydration_habit_id, 'completed', current_week_start + INTERVAL '1 day 11 hours', NOW(), NOW())
        ON CONFLICT DO NOTHING;
        
        -- Miércoles
        INSERT INTO user_habit_logs (user_habit_id, status, completed_at, created_at, updated_at)
        VALUES (hydration_habit_id, 'completed', current_week_start + INTERVAL '2 days 9 hours', NOW(), NOW())
        ON CONFLICT DO NOTHING;
    END IF;
    
    -- Insertar logs de sueño (4 días de la semana)
    IF sleep_habit_id IS NOT NULL THEN
        -- Lunes
        INSERT INTO user_habit_logs (user_habit_id, status, completed_at, created_at, updated_at)
        VALUES (sleep_habit_id, 'completed', current_week_start + INTERVAL '22 hours', NOW(), NOW())
        ON CONFLICT DO NOTHING;
        
        -- Martes
        INSERT INTO user_habit_logs (user_habit_id, status, completed_at, created_at, updated_at)
        VALUES (sleep_habit_id, 'completed', current_week_start + INTERVAL '1 day 23 hours', NOW(), NOW())
        ON CONFLICT DO NOTHING;
        
        -- Miércoles
        INSERT INTO user_habit_logs (user_habit_id, status, completed_at, created_at, updated_at)
        VALUES (sleep_habit_id, 'completed', current_week_start + INTERVAL '2 days 22 hours', NOW(), NOW())
        ON CONFLICT DO NOTHING;
        
        -- Jueves
        INSERT INTO user_habit_logs (user_habit_id, status, completed_at, created_at, updated_at)
        VALUES (sleep_habit_id, 'completed', current_week_start + INTERVAL '3 days 23 hours', NOW(), NOW())
        ON CONFLICT DO NOTHING;
    END IF;
    
    -- Insertar logs de actividad (2 días de la semana)
    IF activity_habit_id IS NOT NULL THEN
        -- Martes
        INSERT INTO user_habit_logs (user_habit_id, status, completed_at, created_at, updated_at)
        VALUES (activity_habit_id, 'completed', current_week_start + INTERVAL '1 day 18 hours', NOW(), NOW())
        ON CONFLICT DO NOTHING;
        
        -- Jueves
        INSERT INTO user_habit_logs (user_habit_id, status, completed_at, created_at, updated_at)
        VALUES (activity_habit_id, 'completed', current_week_start + INTERVAL '3 days 17 hours', NOW(), NOW())
        ON CONFLICT DO NOTHING;
    END IF;
    
    RAISE NOTICE 'Logs de hábitos insertados para el usuario: %', current_user_id;
END $$;