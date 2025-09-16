-- Habilitar RLS correctamente en profiles y user_roles con políticas seguras
-- El usuario tiene razón: deshabilitar RLS no es una buena práctica de seguridad

-- 1. HABILITAR RLS EN PROFILES
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Políticas para profiles (simples y sin recursión)
CREATE POLICY "profiles_select_own" ON profiles
    FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "profiles_insert_own" ON profiles
    FOR INSERT
    WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_own" ON profiles
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_delete_own" ON profiles
    FOR DELETE
    USING (auth.uid() = id);

-- 2. HABILITAR RLS EN USER_ROLES
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- Políticas para user_roles (usando auth.uid() directamente, sin joins)
CREATE POLICY "user_roles_select_own" ON user_roles
    FOR SELECT
    USING (auth.uid()::text = user_id::text);

CREATE POLICY "user_roles_insert_own" ON user_roles
    FOR INSERT
    WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "user_roles_update_own" ON user_roles
    FOR UPDATE
    USING (auth.uid()::text = user_id::text)
    WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "user_roles_delete_own" ON user_roles
    FOR DELETE
    USING (auth.uid()::text = user_id::text);

-- 3. PERMISOS PARA ROLES AUTENTICADOS
GRANT SELECT, INSERT, UPDATE, DELETE ON profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_roles TO authenticated;
GRANT SELECT ON roles TO authenticated;
GRANT SELECT ON roles TO anon;

-- 4. VERIFICAR QUE LAS POLÍTICAS FUNCIONAN
-- Mostrar todas las políticas activas
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename IN ('profiles', 'user_roles')
ORDER BY tablename, policyname;

-- Verificar que RLS está habilitado
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN ('profiles', 'user_roles');