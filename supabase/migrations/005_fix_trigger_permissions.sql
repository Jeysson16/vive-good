-- Otorgar permisos necesarios para que el trigger funcione correctamente
-- El trigger handle_new_user necesita insertar en profiles y user_roles

-- Otorgar permisos INSERT en user_roles para el rol authenticated
GRANT INSERT ON user_roles TO authenticated;

-- Otorgar permisos INSERT en profiles para el rol authenticated
GRANT INSERT ON profiles TO authenticated;

-- Crear política para permitir INSERT en user_roles durante el registro
CREATE POLICY "Allow insert during user registration" ON user_roles
    FOR INSERT WITH CHECK (true);

-- Verificar que la función handle_new_user tenga los permisos correctos
-- La función ya está marcada como SECURITY DEFINER, lo que debería ser suficiente

-- Verificar permisos actuales
SELECT 'Permisos para user_roles:' as info;
SELECT grantee, table_name, privilege_type 
FROM information_schema.role_table_grants 
WHERE table_schema = 'public' 
AND table_name = 'user_roles' 
AND grantee IN ('anon', 'authenticated') 
ORDER BY grantee;