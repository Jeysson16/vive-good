-- Migración para crear el perfil faltante del usuario registrado
-- Fecha: 2024-12-19

-- 1. Crear perfil para el usuario que se registró pero no tiene perfil
-- Usuario ID: 09b37490-eccf-498b-8497-358c2abe08b5
INSERT INTO public.profiles (id, first_name, last_name, email, created_at, updated_at)
SELECT 
    u.id,
    COALESCE(u.raw_user_meta_data->>'first_name', 'Usuario'),
    COALESCE(u.raw_user_meta_data->>'last_name', 'Nuevo'),
    u.email,
    NOW(),
    NOW()
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE u.id = '09b37490-eccf-498b-8497-358c2abe08b5'
AND p.id IS NULL;

-- 2. Asignar rol por defecto al usuario
INSERT INTO public.user_roles (user_id, role_id, created_at)
SELECT 
    '09b37490-eccf-498b-8497-358c2abe08b5',
    r.id,
    NOW()
FROM public.roles r
LEFT JOIN public.user_roles ur ON ur.user_id = '09b37490-eccf-498b-8497-358c2abe08b5' AND ur.role_id = r.id
WHERE r.name = 'user'
AND ur.id IS NULL;

-- 3. Verificar que el perfil se creó correctamente
SELECT 
    'Perfil creado para usuario' as info,
    p.id,
    p.first_name,
    p.last_name,
    p.email
FROM public.profiles p
WHERE p.id = '09b37490-eccf-498b-8497-358c2abe08b5';

-- 4. Verificar que el rol se asignó correctamente
SELECT 
    'Rol asignado' as info,
    ur.user_id,
    r.name as role_name
FROM public.user_roles ur
INNER JOIN public.roles r ON ur.role_id = r.id
WHERE ur.user_id = '09b37490-eccf-498b-8497-358c2abe08b5';

SELECT 'Perfil creado exitosamente para el usuario registrado' as resultado;