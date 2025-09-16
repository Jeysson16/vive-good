-- Test del stored procedure get_habit_suggestions
-- Verificar si retorna datos

-- 1. Verificar datos base
SELECT 'Total habits activos:' as info, COUNT(*) as count FROM habits WHERE is_active = true;
SELECT 'Total categorías:' as info, COUNT(*) as count FROM categories;
SELECT 'Total user_habits:' as info, COUNT(*) as count FROM user_habits;

-- 2. Ver algunos hábitos activos
SELECT h.id, h.name, h.description, c.name as category_name, c.icon as category_icon
FROM habits h
JOIN categories c ON h.category_id = c.id
WHERE h.is_active = true
LIMIT 5;

-- 3. Verificar si hay usuarios reales en auth.users
SELECT 'Usuarios en auth.users:' as info, COUNT(*) as count FROM auth.users;

-- 4. Probar el stored procedure con un UUID ficticio
SELECT 'Resultado del SP con UUID ficticio:' as info;
SELECT * FROM get_habit_suggestions('550e8400-e29b-41d4-a716-446655440000'::uuid, null, 10);

-- 5. Verificar que la función existe
SELECT 'Función get_habit_suggestions existe:' as info, 
       CASE WHEN EXISTS (
           SELECT 1 FROM pg_proc 
           WHERE proname = 'get_habit_suggestions'
       ) THEN 'SÍ' ELSE 'NO' END as existe;