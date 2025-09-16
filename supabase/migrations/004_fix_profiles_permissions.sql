-- Otorgar permisos SELECT en profiles para rol anon
-- Esto es necesario para que el método _getUserProfile funcione correctamente
GRANT SELECT ON profiles TO anon;

-- Verificar permisos actuales
SELECT 'Permisos actuales para profiles:' as info;
SELECT grantee, table_name, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_schema = 'public' 
AND table_name = 'profiles' 
AND grantee IN ('anon', 'authenticated') 
ORDER BY grantee;