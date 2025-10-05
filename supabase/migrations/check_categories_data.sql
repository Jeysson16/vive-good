-- Consulta para verificar las categorías existentes
SELECT id, name, description, color, icon, created_at, updated_at, created_by 
FROM categories 
ORDER BY name