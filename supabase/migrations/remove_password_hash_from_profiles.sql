-- Eliminar el campo password_hash de la tabla profiles
-- Este campo no es necesario cuando usamos Supabase Auth oficial

ALTER TABLE profiles DROP COLUMN IF EXISTS password_hash;

-- Verificar que las políticas RLS permitan inserción para usuarios autenticados
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;

-- Crear políticas RLS correctas
CREATE POLICY "Users can insert their own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Asegurar que RLS esté habilitado
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Comentario sobre la estructura final
COMMENT ON TABLE profiles IS 'Tabla de perfiles de usuario - solo información básica, las contraseñas se manejan por Supabase Auth';