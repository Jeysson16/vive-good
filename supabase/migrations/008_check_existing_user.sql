-- Verificar si el usuario ya existe en auth.users
SELECT 
    id,
    email,
    created_at,
    email_confirmed_at,
    last_sign_in_at
FROM auth.users 
WHERE email = 'jeysson_s.r@hotmail.com';

-- Verificar si existe perfil para este usuario
SELECT 
    id,
    email,
    first_name,
    last_name,
    created_at
FROM profiles 
WHERE email = 'jeysson_s.r@hotmail.com';

-- Contar total de usuarios
SELECT COUNT(*) as total_users FROM auth.users;
SELECT COUNT(*) as total_profiles FROM profiles;