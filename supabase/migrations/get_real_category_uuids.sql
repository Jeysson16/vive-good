-- Obtener los UUIDs reales de las categorías para corregir el mapeo
SELECT id, name, description, color, icon 
FROM categories 
ORDER BY name;