-- Debug: Verificar datos en tabla habits
SELECT 
    COUNT(*) as total_habits,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_habits,
    COUNT(CASE WHEN category_id IS NOT NULL THEN 1 END) as habits_with_category
FROM habits;

-- Mostrar algunos hábitos de ejemplo
SELECT 
    h.id,
    h.name,
    h.description,
    h.is_active,
    c.name as category_name,
    c.icon as category_icon
FROM habits h
LEFT JOIN categories c ON h.category_id = c.id
WHERE h.is_active = true
LIMIT 5;

-- Verificar si hay categorías
SELECT COUNT(*) as total_categories FROM categories;

-- Verificar user_habits para entender el filtro
SELECT COUNT(*) as total_user_habits FROM user_habits;