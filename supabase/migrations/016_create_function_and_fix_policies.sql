-- Crear función assign_user_role y corregir políticas RLS

-- Primero, eliminar todas las políticas problemáticas
DROP POLICY IF EXISTS "Users can view their own roles" ON user_roles;
DROP POLICY IF EXISTS "Users can insert their own roles" ON user_roles;
DROP POLICY IF EXISTS "Users can update their own roles" ON user_roles;
DROP POLICY IF EXISTS "Users can delete their own roles" ON user_roles;
DROP POLICY IF EXISTS "user_roles_select_policy" ON user_roles;
DROP POLICY IF EXISTS "user_roles_insert_policy" ON user_roles;
DROP POLICY IF EXISTS "user_roles_update_policy" ON user_roles;
DROP POLICY IF EXISTS "user_roles_delete_policy" ON user_roles;
DROP POLICY IF EXISTS "simple_user_roles_select" ON user_roles;
DROP POLICY IF EXISTS "simple_user_roles_insert" ON user_roles;
DROP POLICY IF EXISTS "simple_user_roles_update" ON user_roles;
DROP POLICY IF EXISTS "simple_user_roles_delete" ON user_roles;

-- Deshabilitar RLS temporalmente
ALTER TABLE user_roles DISABLE ROW LEVEL SECURITY;

-- Crear la función assign_user_role
CREATE OR REPLACE FUNCTION assign_user_role(user_uuid TEXT, role_name TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    target_role_id UUID;
BEGIN
    -- Obtener el ID del rol
    SELECT id INTO target_role_id
    FROM roles
    WHERE name = role_name
    LIMIT 1;
    
    IF target_role_id IS NULL THEN
        RAISE EXCEPTION 'Rol % no encontrado', role_name;
    END IF;
    
    -- Insertar la relación user_role directamente
    INSERT INTO user_roles (user_id, role_id)
    VALUES (user_uuid::UUID, target_role_id)
    ON CONFLICT DO NOTHING;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al asignar rol: %', SQLERRM;
END;
$$;

-- Conceder permisos de ejecución
GRANT EXECUTE ON FUNCTION assign_user_role(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION assign_user_role(TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION assign_user_role(TEXT, TEXT) TO service_role;

-- Habilitar RLS nuevamente
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- Crear políticas muy simples que no causen recursión
-- Solo permitir SELECT a usuarios autenticados
CREATE POLICY "allow_authenticated_select" ON user_roles
    FOR SELECT
    TO authenticated
    USING (true);

-- Solo permitir INSERT/UPDATE/DELETE a service_role (para la función)
CREATE POLICY "allow_service_role_all" ON user_roles
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Conceder permisos básicos
GRANT SELECT ON user_roles TO authenticated;
GRANT SELECT ON user_roles TO anon;