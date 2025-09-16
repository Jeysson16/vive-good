-- Test del stored procedure get_habit_suggestions
-- Primero verificar si existe el stored procedure
SELECT proname, prosrc FROM pg_proc WHERE proname = 'get_habit_suggestions';

-- Probar el stored procedure con un user_id de prueba
-- Usar un UUID que probablemente no exista para ver todos los hábitos
SELECT * FROM get_habit_suggestions(
    p_user_id := '00000000-0000-0000-0000-000000000000'::uuid,
    p_category_id := NULL,
    p_limit := 10
);

-- Verificar datos base
SELECT 'Habits count:' as info, COUNT(*)::text as value FROM habits WHERE is_active = true
UNION ALL
SELECT 'Categories count:' as info, COUNT(*)::text as value FROM categories
UNION ALL
SELECT 'User habits count:' as info, COUNT(*)::text as value FROM user_habits;

-- Mostrar algunos hábitos activos
SELECT h.name, h.description, c.name as category, h.is_active
FROM habits h
LEFT JOIN categories c ON h.category_id = c.id
WHERE h.is_active = true
LIMIT 3;