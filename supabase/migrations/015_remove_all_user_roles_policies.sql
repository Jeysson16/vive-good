-- Eliminar todas las políticas RLS problemáticas de user_roles
-- y usar solo la función assign_user_role para asignación de roles

-- Eliminar todas las políticas existentes de user_roles
DROP POLICY IF EXISTS "Users can view their own roles" ON user_roles;
DROP POLICY IF EXISTS "Users can insert their own roles" ON user_roles;
DROP POLICY IF EXISTS "Users can update their own roles" ON user_roles;
DROP POLICY IF EXISTS "Users can delete their own roles" ON user_roles;
DROP POLICY IF EXISTS "user_roles_select_policy" ON user_roles;
DROP POLICY IF EXISTS "user_roles_insert_policy" ON user_roles;
DROP POLICY IF EXISTS "user_roles_update_policy" ON user_roles;
DROP POLICY IF EXISTS "user_roles_delete_policy" ON user_roles;

-- Deshabilitar RLS temporalmente para user_roles
ALTER TABLE user_roles DISABLE ROW LEVEL SECURITY;

-- Crear políticas simples sin recursión
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- Política simple para SELECT - solo permite ver roles propios
CREATE POLICY "simple_user_roles_select" ON user_roles
    FOR SELECT
    USING (user_id::text = auth.uid()::text);

-- Política simple para INSERT - solo permite insertar con user_id propio
CREATE POLICY "simple_user_roles_insert" ON user_roles
    FOR INSERT
    WITH CHECK (user_id::text = auth.uid()::text);

-- Política simple para UPDATE - solo permite actualizar roles propios
CREATE POLICY "simple_user_roles_update" ON user_roles
    FOR UPDATE
    USING (user_id::text = auth.uid()::text)
    WITH CHECK (user_id::text = auth.uid()::text);

-- Política simple para DELETE - solo permite eliminar roles propios
CREATE POLICY "simple_user_roles_delete" ON user_roles
    FOR DELETE
    USING (user_id::text = auth.uid()::text);

-- Conceder permisos básicos a los roles
GRANT SELECT, INSERT, UPDATE, DELETE ON user_roles TO authenticated;
GRANT SELECT ON user_roles TO anon;

-- Verificar que la función assign_user_role existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'assign_user_role') THEN
        -- Crear la función si no existe
        CREATE OR REPLACE FUNCTION assign_user_role(user_uuid TEXT, role_name TEXT)
        RETURNS VOID
        LANGUAGE plpgsql
        SECURITY DEFINER
        AS $func$
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
            
            -- Insertar la relación user_role directamente (sin políticas RLS)
            INSERT INTO user_roles (user_id, role_id)
            VALUES (user_uuid::UUID, target_role_id)
            ON CONFLICT (user_id, role_id) DO NOTHING;
            
        EXCEPTION
            WHEN OTHERS THEN
                RAISE EXCEPTION 'Error al asignar rol: %', SQLERRM;
        END;
        $func$;
    END IF;
END
$$;

-- Conceder permisos de ejecución a la función
GRANT EXECUTE ON FUNCTION assign_user_role(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION assign_user_role(TEXT, TEXT) TO anon;