-- Consulta para obtener los UUIDs reales de las categorías
-- Esto nos ayudará a corregir el mapeo hardcodeado en el código

SELECT 
    id,
    name,
    description,
    color,
    icon
FROM categories 
ORDER BY name;

-- También mostrar el mapeo que necesitamos para el código
SELECT 
    CONCAT('''', name, ''': ''', id, ''',') as mapping_line
FROM categories 
ORDER BY name;