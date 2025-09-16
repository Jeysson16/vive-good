-- Migración para debuggear la ejecución del trigger
-- Fecha: 2024-12-19

-- 1. Verificar si el trigger existe y está activo
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- 2. Verificar usuarios recientes en auth.users
SELECT 
    'Usuarios en auth.users (últimos 5)' as info,
    id,
    email,
    created_at,
    raw_user_meta_data
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- 3. Verificar perfiles correspondientes
SELECT 
    'Perfiles en public.profiles' as info,
    p.id,
    p.email,
    p.first_name,
    p.last_name,
    p.created_at
FROM public.profiles p
INNER JOIN auth.users u ON p.id = u.id
ORDER BY p.created_at DESC 
LIMIT 5;

-- 4. Verificar roles asignados
SELECT 
    'Roles asignados en user_roles' as info,
    ur.user_id,
    ur.role_id,
    r.name as role_name,
    ur.created_at
FROM public.user_roles ur
INNER JOIN public.roles r ON ur.role_id = r.id
INNER JOIN auth.users u ON ur.user_id = u.id
ORDER BY ur.created_at DESC 
LIMIT 5;

-- 5. Buscar usuarios sin perfil
SELECT 
    'Usuarios sin perfil' as info,
    u.id,
    u.email,
    u.created_at
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL
ORDER BY u.created_at DESC;

-- 6. Verificar políticas RLS en profiles
SELECT 
    'Políticas RLS en profiles' as info,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'profiles';

-- 7. Verificar permisos en las tablas
SELECT 
    'Permisos en profiles' as info,
    grantee,
    privilege_type
FROM information_schema.role_table_grants 
WHERE table_name = 'profiles' 
AND grantee IN ('anon', 'authenticated');

SELECT 
    'Permisos en user_roles' as info,
    grantee,
    privilege_type
FROM information_schema.role_table_grants 
WHERE table_name = 'user_roles' 
AND grantee IN ('anon', 'authenticated');

-- 8. Probar manualmente la función del trigger
SELECT 'Probando función handle_new_user manualmente' as test;

-- Crear un usuario de prueba temporal para verificar el trigger
DO $$
DECLARE
    test_user_id uuid := 'test-user-' || extract(epoch from now())::text;
    test_email text := 'test-' || extract(epoch from now())::text || '@example.com';
BEGIN
    -- Simular la inserción que haría auth.users
    RAISE NOTICE 'Simulando creación de usuario con ID: %', test_user_id;
    
    -- Ejecutar la función directamente
    PERFORM public.handle_new_user();
    
    RAISE NOTICE 'Función ejecutada sin errores';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error en función handle_new_user: %', SQLERRM;
END $$;

SELECT 'Debug completado' as resultado;