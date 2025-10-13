-- Migración temporal para obtener el mapeo de categorías
-- Esto nos ayudará a corregir el código Dart

-- Mostrar todas las categorías con sus UUIDs
SELECT 
    name,
    id,
    CONCAT('''', name, ''': ''', id, ''',') as dart_mapping
FROM categories 
ORDER BY name;

-- Verificar que todas las categorías esperadas existen
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM categories WHERE name = 'Alimentación') THEN '✓ Alimentación existe'
        ELSE '✗ Alimentación NO existe'
    END as alimentacion_check,
    CASE 
        WHEN EXISTS (SELECT 1 FROM categories WHERE name = 'Actividad Física') THEN '✓ Actividad Física existe'
        ELSE '✗ Actividad Física NO existe'
    END as actividad_fisica_check,
    CASE 
        WHEN EXISTS (SELECT 1 FROM categories WHERE name = 'Sueño') THEN '✓ Sueño existe'
        ELSE '✗ Sueño NO existe'
    END as sueno_check,
    CASE 
        WHEN EXISTS (SELECT 1 FROM categories WHERE name = 'Hidratación') THEN '✓ Hidratación existe'
        ELSE '✗ Hidratación NO existe'
    END as hidratacion_check,
    CASE 
        WHEN EXISTS (SELECT 1 FROM categories WHERE name = 'Bienestar Mental') THEN '✓ Bienestar Mental existe'
        ELSE '✗ Bienestar Mental NO existe'
    END as bienestar_check,
    CASE 
        WHEN EXISTS (SELECT 1 FROM categories WHERE name = 'Productividad') THEN '✓ Productividad existe'
        ELSE '✗ Productividad NO existe'
    END as productividad_check;