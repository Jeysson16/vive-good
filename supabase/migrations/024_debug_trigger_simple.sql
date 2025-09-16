-- Migración para debuggear la ejecución del trigger (versión corregida)
-- Fecha: 2024-12-19

-- 1. Verificar si el trigger existe y está activo
SELECT 
    'Estado del trigger' as info,
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- 2. Verificar usuarios recientes en auth.users
SELECT 
    'Usuarios recientes en auth.users' as info,
    id,
    email,
    created_at
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 3;

-- 3. Verificar perfiles correspondientes
SELECT 
    'Perfiles en public.profiles' as info,
    p.id,
    p.email,
    p.first_name,
    p.last_name,
    p.created_at
FROM public.profiles p
ORDER BY p.created_at DESC 
LIMIT 3;

-- 4. Verificar roles asignados
SELECT 
    'Roles asignados' as info,
    ur.user_id,
    r.name as role_name,
    ur.created_at
FROM public.user_roles ur
INNER JOIN public.roles r ON ur.role_id = r.id
ORDER BY ur.created_at DESC 
LIMIT 3;

-- 5. Buscar usuarios sin perfil
SELECT 
    'Usuarios sin perfil' as info,
    u.id,
    u.email,
    u.created_at
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL
ORDER BY u.created_at DESC
LIMIT 5;

-- 6. Verificar políticas RLS en profiles
SELECT 
    'Políticas RLS activas' as info,
    tablename,
    policyname,
    cmd,
    roles
FROM pg_policies 
WHERE tablename IN ('profiles', 'user_roles');

-- 7. Verificar permisos en las tablas
SELECT 
    'Permisos en profiles' as info,
    grantee,
    privilege_type
FROM information_schema.role_table_grants 
WHERE table_name = 'profiles' 
AND grantee IN ('anon', 'authenticated');

-- 8. Verificar que existe el rol por defecto
SELECT 
    'Rol por defecto' as info,
    id,
    name,
    description
FROM public.roles 
WHERE name = 'user';

-- 9. Verificar la función del trigger
SELECT 
    'Función del trigger' as info,
    routine_name,
    routine_type,
    security_type
FROM information_schema.routines 
WHERE routine_name = 'handle_new_user';

SELECT 'Debug completado exitosamente' as resultado;