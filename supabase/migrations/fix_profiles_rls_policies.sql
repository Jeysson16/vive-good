-- Verificar y corregir las políticas RLS para la tabla profiles
-- El problema es que auth.uid() puede no estar disponible durante la inserción

-- Eliminar todas las políticas existentes
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON profiles;
DROP POLICY IF EXISTS "Enable read access for all users" ON profiles;
DROP POLICY IF EXISTS "Enable update for users based on email" ON profiles;

-- Crear políticas más permisivas para usuarios autenticados
-- Política para inserción: permitir a usuarios autenticados insertar su propio perfil
CREATE POLICY "Enable insert for authenticated users" ON profiles
    FOR INSERT 
    TO authenticated 
    WITH CHECK (auth.uid() = id);

-- Política para lectura: permitir a usuarios autenticados ver su propio perfil
CREATE POLICY "Enable read for own profile" ON profiles
    FOR SELECT 
    TO authenticated 
    USING (auth.uid() = id);

-- Política para actualización: permitir a usuarios autenticados actualizar su propio perfil
CREATE POLICY "Enable update for own profile" ON profiles
    FOR UPDATE 
    TO authenticated 
    USING (auth.uid() = id) 
    WITH CHECK (auth.uid() = id);

-- Asegurar que RLS esté habilitado
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Verificar las políticas creadas
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'profiles';

-- Comentario de verificación
SELECT 'Políticas RLS actualizadas para tabla profiles' as status;