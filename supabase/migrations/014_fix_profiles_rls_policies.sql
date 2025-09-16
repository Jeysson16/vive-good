-- Corregir políticas RLS para la tabla profiles
-- Permitir inserción y selección para usuarios autenticados

-- Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

-- Crear política para permitir inserción de perfiles
CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Crear política para permitir lectura de perfiles propios
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Crear política para permitir actualización de perfiles propios
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Verificar que RLS esté habilitado
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Otorgar permisos básicos a los roles
GRANT SELECT, INSERT, UPDATE ON profiles TO authenticated;
GRANT SELECT ON profiles TO anon;