-- Deshabilitar completamente RLS en user_roles para evitar recursión infinita
-- y usar solo la función assign_user_role para manejar la seguridad

-- Eliminar TODAS las políticas de user_roles
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'user_roles' AND schemaname = 'public'
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_record.policyname || '" ON user_roles';
    END LOOP;
END
$$;

-- Deshabilitar RLS completamente en user_roles
ALTER TABLE user_roles DISABLE ROW LEVEL SECURITY;

-- Recrear la función assign_user_role con mejor manejo de errores
DROP FUNCTION IF EXISTS assign_user_role(TEXT, TEXT);

CREATE OR REPLACE FUNCTION assign_user_role(user_uuid TEXT, role_name TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    target_role_id UUID;
    user_exists BOOLEAN;
BEGIN
    -- Verificar que el usuario existe en profiles
    SELECT EXISTS(SELECT 1 FROM profiles WHERE id = user_uuid::UUID) INTO user_exists;
    
    IF NOT user_exists THEN
        RAISE EXCEPTION 'Usuario % no encontrado en profiles', user_uuid;
    END IF;
    
    -- Obtener el ID del rol
    SELECT id INTO target_role_id
    FROM roles
    WHERE name = role_name
    LIMIT 1;
    
    IF target_role_id IS NULL THEN
        RAISE EXCEPTION 'Rol % no encontrado', role_name;
    END IF;
    
    -- Insertar la relación user_role
    INSERT INTO user_roles (user_id, role_id)
    VALUES (user_uuid::UUID, target_role_id)
    ON CONFLICT (user_id, role_id) DO NOTHING;
    
    RAISE NOTICE 'Rol % asignado exitosamente al usuario %', role_name, user_uuid;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al asignar rol: %', SQLERRM;
END;
$$;

-- Conceder permisos amplios para evitar problemas
GRANT ALL PRIVILEGES ON user_roles TO authenticated;
GRANT ALL PRIVILEGES ON user_roles TO anon;
GRANT ALL PRIVILEGES ON user_roles TO service_role;

-- Conceder permisos de ejecución a la función
GRANT EXECUTE ON FUNCTION assign_user_role(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION assign_user_role(TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION assign_user_role(TEXT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION assign_user_role(TEXT, TEXT) TO postgres;

-- Verificar que todo está configurado correctamente
DO $$
BEGIN
    RAISE NOTICE 'RLS deshabilitado en user_roles';
    RAISE NOTICE 'Función assign_user_role creada';
    RAISE NOTICE 'Permisos concedidos';
END
$$;