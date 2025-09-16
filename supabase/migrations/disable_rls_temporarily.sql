-- Deshabilitar temporalmente RLS para la tabla profiles
-- Esto permitirá que el registro funcione mientras investigamos el problema de contexto de auth

-- Deshabilitar RLS temporalmente
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- Eliminar todas las políticas existentes
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON profiles;
DROP POLICY IF EXISTS "Enable read for own profile" ON profiles;
DROP POLICY IF EXISTS "Enable update for own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;

-- Comentario explicativo
COMMENT ON TABLE profiles IS 'RLS temporalmente deshabilitado para permitir registro. Las contraseñas se manejan por Supabase Auth';

-- Verificar el estado
SELECT 
    schemaname, 
    tablename, 
    rowsecurity as rls_enabled,
    CASE 
        WHEN rowsecurity THEN 'RLS habilitado'
        ELSE 'RLS deshabilitado'
    END as status
FROM pg_tables 
WHERE tablename = 'profiles';

SELECT 'RLS deshabilitado temporalmente para tabla profiles' as resultado;