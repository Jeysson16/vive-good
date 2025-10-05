-- Verificar si hay categorías en la tabla
SELECT COUNT(*) as total_categories FROM categories;

-- Mostrar todas las categorías
SELECT id, name, description, color, icon 
FROM categories 
ORDER BY name;