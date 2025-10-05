-- Debug query to check user_habits data
SELECT 
    uh.id,
    uh.user_id,
    uh.habit_id,
    uh.custom_name,
    uh.is_active,
    uh.is_public,
    h.name as habit_name,
    c.name as category_name
FROM user_habits uh
LEFT JOIN habits h ON uh.habit_id = h.id
LEFT JOIN categories c ON uh.category_id = c.id OR h.category_id = c.id
ORDER BY uh.created_at;

-- Also check if there are any users in auth.users
SELECT COUNT(*) as total_users FROM auth.users;

-- Check current user session
SELECT auth.uid() as current_user_id;