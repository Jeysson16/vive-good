-- Query para obtener categorías reales
SELECT 
    id,
    name,
    description,
    color,
    icon,
    created_at
FROM categories 
ORDER BY name;

-- También verificar si hay datos
SELECT COUNT(*) as total_categories