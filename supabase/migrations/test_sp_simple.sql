-- Prueba simple del stored procedure

-- 1. Verificar datos básicos
SELECT COUNT(*) as total_habits FROM habits WHERE is_active = true;
SELECT COUNT(*) as total_categories FROM categories;

-- 2. Probar SP sin filtros
SELECT COUNT(*) as suggestions_count FROM get_habit_suggestions(null, null, 10);

-- 3. Mostrar algunas sugerencias
SELECT id, name, description, category_name, category_icon 
FROM get_habit_suggestions(null, null, 5);

-- 4. Probar con user_id ficticio
SELECT COUNT(*) as suggestions_with_user FROM get_habit_suggestions('550e8400-e29b-41d4-a716-446655440000'::uuid, null, 10);