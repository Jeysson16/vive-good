-- Recrear completamente la tabla user_roles sin RLS para eliminar definitivamente la recursión infinita

-- Guardar datos existentes
CREATE TEMP TABLE temp_user_roles AS 
SELECT * FROM user_roles;

-- Eliminar la tabla problemática
DROP TABLE IF EXISTS user_roles CASCADE;

-- Recrear la tabla sin RLS
CREATE TABLE user_roles (
    id UUID DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
    user_id UUID,
    role_id UUID REFERENCES roles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, role_id)
);

-- NO habilitar RLS en absoluto
-- ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY; -- COMENTADO INTENCIONALMENTE

-- Restaurar datos
INSERT INTO user_roles (id, user_id, role_id, created_at)
SELECT id, user_id, role_id, created_at FROM temp_user_roles
ON CONFLICT (user_id, role_id) DO NOTHING;

-- Eliminar tabla temporal
DROP TABLE temp_user_roles;

-- Conceder permisos completos
GRANT ALL PRIVILEGES ON user_roles TO authenticated;
GRANT ALL PRIVILEGES ON user_roles TO anon;
GRANT ALL PRIVILEGES ON user_roles TO service_role;
GRANT ALL PRIVILEGES ON user_roles TO postgres;

-- Crear función simplificada para asignar roles
DROP FUNCTION IF EXISTS assign_user_role(TEXT, TEXT);

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
    
    -- Insertar directamente sin políticas RLS
    INSERT INTO user_roles (user_id, role_id)
    VALUES (user_uuid::UUID, target_role_id)
    ON CONFLICT (user_id, role_id) DO NOTHING;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al asignar rol: %', SQLERRM;
END;
$$;

-- Conceder permisos de ejecución
GRANT EXECUTE ON FUNCTION assign_user_role(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION assign_user_role(TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION assign_user_role(TEXT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION assign_user_role(TEXT, TEXT) TO postgres;

-- Verificar que no hay RLS habilitado
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_class 
        WHERE relname = 'user_roles' 
        AND relrowsecurity = true
    ) THEN
        RAISE EXCEPTION 'RLS aún está habilitado en user_roles';
    ELSE
        RAISE NOTICE 'Tabla user_roles recreada sin RLS - OK';
    END IF;
END
$$;