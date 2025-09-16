-- Migración para corregir el trigger automático y las relaciones
-- Fecha: 2024-12-19

-- 1. Primero, eliminar la relación incorrecta entre user_roles.user_id y profiles.id
ALTER TABLE user_roles DROP CONSTRAINT IF EXISTS user_roles_user_id_profiles_fkey;

-- 2. Crear la relación correcta entre user_roles.user_id y auth.users.id
ALTER TABLE user_roles 
ADD CONSTRAINT user_roles_user_id_auth_users_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- 3. Crear función para el trigger automático
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
    default_role_id uuid;
BEGIN
    -- Obtener el ID del rol 'user' por defecto
    SELECT id INTO default_role_id 
    FROM public.roles 
    WHERE name = 'user' 
    LIMIT 1;
    
    -- Crear perfil automáticamente
    INSERT INTO public.profiles (id, first_name, last_name, email)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'first_name', 'Usuario'),
        COALESCE(NEW.raw_user_meta_data->>'last_name', 'Nuevo'),
        NEW.email
    );
    
    -- Asignar rol por defecto si existe
    IF default_role_id IS NOT NULL THEN
        INSERT INTO public.user_roles (user_id, role_id)
        VALUES (NEW.id, default_role_id);
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log del error pero no fallar el registro
        RAISE WARNING 'Error en trigger handle_new_user: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Eliminar trigger existente si existe
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 5. Crear el trigger en auth.users
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 6. Verificar que existe el rol 'user' por defecto
INSERT INTO public.roles (id, name, description)
VALUES (
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'user',
    'Usuario estándar del sistema'
)
ON CONFLICT (name) DO NOTHING;

-- 7. Limpiar datos inconsistentes en user_roles
-- Eliminar registros donde user_id no existe en auth.users
DELETE FROM public.user_roles 
WHERE user_id NOT IN (SELECT id FROM auth.users);

-- 8. Verificar configuración
SELECT 
    'Trigger creado correctamente' as status,
    COUNT(*) as total_triggers
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

SELECT 
    'Rol por defecto configurado' as status,
    COUNT(*) as total_roles
FROM public.roles 
WHERE name = 'user';

-- 9. Mostrar usuarios sin perfil (para debugging)
SELECT 
    'Usuarios sin perfil' as status,
    COUNT(*) as count
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- 10. Crear perfiles faltantes para usuarios existentes
INSERT INTO public.profiles (id, first_name, last_name, email)
SELECT 
    u.id,
    COALESCE(u.raw_user_meta_data->>'first_name', 'Usuario'),
    COALESCE(u.raw_user_meta_data->>'last_name', 'Existente'),
    u.email
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.id
WHERE p.id IS NULL;

-- 11. Asignar roles faltantes para usuarios existentes
INSERT INTO public.user_roles (user_id, role_id)
SELECT 
    u.id,
    r.id
FROM auth.users u
CROSS JOIN public.roles r
LEFT JOIN public.user_roles ur ON u.id = ur.user_id AND r.id = ur.role_id
WHERE r.name = 'user' AND ur.id IS NULL;

SELECT 'Migración completada exitosamente' as resultado;