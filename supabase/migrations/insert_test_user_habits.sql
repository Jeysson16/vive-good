-- Verificar y corregir datos para el usuario específico
-- Primero verificar que las categorías existen
INSERT INTO categories (id, name, description, icon, color, created_at, updated_at) 
VALUES 
    ('b0231bea-a750-4984-97d8-8ccb3a2bae1c', 'Alimentación', 'Hábitos relacionados con la alimentación saludable', 'restaurant', '#FF9800', NOW(), NOW()),
    ('6d1f2f1b-04ef-497e-97b7-8077ff3b3c69', 'Sueño', 'Hábitos relacionados con el descanso y sueño', 'bedtime', '#9C27B0', NOW(), NOW()),
    ('93688043-4d35-4b2a-9dcd-17482125b1a9', 'Hidratación', 'Hábitos de hidratación', 'local_drink', '#2196F3', NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    icon = EXCLUDED.icon,
    color = EXCLUDED.color,
    updated_at = NOW();

-- Insertar hábitos predefinidos
INSERT INTO habits (id, name, description, category_id, icon_name, icon_color, is_active, created_at, updated_at)
VALUES 
    ('62dedaff-9c0d-4d0f-b99f-1245062adc08', 'Dormir 8 horas', 'Dormir al menos 8 horas diarias', '6d1f2f1b-04ef-497e-97b7-8077ff3b3c69', 'heart', '#4CAF50', true, NOW(), NOW()),
    ('b6cc8839-c20d-4800-bb6f-5a95896d5e0b', 'Beber agua', 'Beber al menos 8 vasos de agua al día', '93688043-4d35-4b2a-9dcd-17482125b1a9', 'local_drink', '#2196F3', true, NOW(), NOW()),
    ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'Desayuno saludable', 'Tomar un desayuno nutritivo', 'b0231bea-a750-4984-97d8-8ccb3a2bae1c', 'restaurant', '#FF9800', true, NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    category_id = EXCLUDED.category_id,
    icon_name = EXCLUDED.icon_name,
    icon_color = EXCLUDED.icon_color,
    is_active = EXCLUDED.is_active,
    updated_at = NOW();

-- Actualizar user_habits existentes para asegurar que estén activos
UPDATE user_habits 
SET 
    is_active = true,
    updated_at = NOW()
WHERE user_id = '8e622f30-084d-4015-a3b8-6ae33e8ee991';

-- Insertar calendar_events para hoy si no existen
INSERT INTO calendar_events (id, user_id, habit_id, title, start_date, start_time, end_time, recurrence_type, is_completed, created_at, updated_at)
SELECT 
    gen_random_uuid(),
    '8e622f30-084d-4015-a3b8-6ae33e8ee991',
    uh.habit_id,
    h.name,
    CURRENT_DATE,
    '08:00:00',
    '08:30:00',
    'daily',
    false,
    NOW(),
    NOW()
FROM user_habits uh
JOIN habits h ON h.id = uh.habit_id
WHERE uh.user_id = '8e622f30-084d-4015-a3b8-6ae33e8ee991'
  AND uh.is_active = true
  AND NOT EXISTS (
    SELECT 1 FROM calendar_events ce 
    WHERE ce.user_id = uh.user_id 
      AND ce.habit_id = uh.habit_id 
      AND ce.start_date = CURRENT_DATE
  );

-- Verificar que los datos están correctos
SELECT 'Verification: user_habits count' as info, COUNT(*) as count FROM user_habits WHERE user_id = '8e622f30-084d-4015-a3b8-6ae33e8ee991' AND is_active = true;
SELECT 'Verification: calendar_events count' as info, COUNT(*) as count FROM calendar_events WHERE user_id = '8e622f30-084d-4015-a3b8-6ae33e8ee991' AND start_date = CURRENT_DATE;

-- Probar el stored procedure nuevamente
SELECT 'Testing stored procedure:' as info;
SELECT * FROM get_dashboard_habits('8e622f30-084d-4015-a3b8-6ae33e8ee991', CURRENT_DATE);