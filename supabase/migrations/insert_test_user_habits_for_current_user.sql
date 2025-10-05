-- Insert test user habits for the current user
-- First, let's get some habit IDs from the habits table
INSERT INTO user_habits (
    user_id,
    habit_id,
    frequency,
    start_date,
    is_active
)
SELECT 
    auth.uid() as user_id,
    h.id as habit_id,
    'daily' as frequency,
    CURRENT_DATE as start_date,
    true as is_active
FROM habits h
LIMIT 3;

-- Verify the insertion
SELECT 
    uh.id,
    uh.user_id,
    uh.habit_id,
    h.name as habit_name,
    c.name as category_name
FROM user_habits uh
JOIN habits h ON uh.habit_id = h.id
JOIN categories c ON h.category_id = c.id
WHERE uh.user_id = auth.uid();