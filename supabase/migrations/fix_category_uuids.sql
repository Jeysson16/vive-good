-- Migración para asegurar que todas las categorías tengan UUIDs consistentes
-- Esto corrige el problema de UUID inválido en la sincronización de hábitos

-- Insertar o actualizar categorías con UUIDs específicos
INSERT INTO categories (id, name, description, color, icon, created_at, updated_at) 
VALUES 
    -- Categorías principales con UUIDs específicos
    ('b0231bea-a750-4984-97d8-8ccb3a2bae1c', 'Alimentación', 'Hábitos relacionados con una alimentación saludable', '#4CAF50', 'utensils', NOW(), NOW()),
    ('2196f3aa-1234-4567-89ab-cdef12345678', 'Actividad Física', 'Ejercicios y actividades físicas', '#2196F3', 'activity', NOW(), NOW()),
    ('6d1f2f1b-04ef-497e-97b7-8077ff3b3c69', 'Sueño', 'Hábitos para mejorar la calidad del sueño', '#9C27B0', 'moon', NOW(), NOW()),
    ('93688043-4d35-4b2a-9dcd-17482125b1a9', 'Hidratación', 'Consumo adecuado de líquidos', '#00BCD4', 'droplet', NOW(), NOW()),
    ('ff9800bb-5678-4567-89ab-cdef12345678', 'Bienestar Mental', 'Actividades para la salud mental', '#FF9800', 'brain', NOW(), NOW()),
    ('795548cc-9012-4567-89ab-cdef12345678', 'Productividad', 'Hábitos para mejorar la productividad', '#795548', 'target', NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    color = EXCLUDED.color,
    icon = EXCLUDED.icon,
    updated_at = NOW();

-- Verificar que todas las categorías fueron creadas correctamente
SELECT 
    name,
    id,
    color,
    icon
FROM categories 
ORDER BY name;

-- Mostrar el mapeo para actualizar el código Dart
SELECT 
    CONCAT('''', name, ''': ''', id, ''',') as dart_mapping
FROM categories 
ORDER BY name;