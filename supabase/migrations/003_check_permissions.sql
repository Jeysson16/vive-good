-- Verificar permisos actuales
SELECT grantee, table_name, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_schema = 'public' 
AND grantee IN ('anon', 'authenticated') 
ORDER BY table_name, grantee;

-- Verificar políticas RLS existentes
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'public';

-- Agregar política faltante para INSERT en profiles (necesaria para el trigger)
CREATE POLICY "Allow insert for new user registration" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Verificar que el trigger existe
SELECT trigger_name, event_manipulation, event_object_table 
FROM information_schema.triggers 
WHERE trigger_schema = 'public' OR event_object_schema = 'auth';