-- Limpiar usuario existente para permitir registro limpio
-- IMPORTANTE: Solo ejecutar en desarrollo

-- Eliminar perfil si existe
DELETE FROM profiles WHERE email = 'jeysson_s.r@hotmail.com';

-- Eliminar roles de usuario si existen
DELETE FROM user_roles 
WHERE user_id IN (
    SELECT id FROM auth.users WHERE email = 'jeysson_s.r@hotmail.com'
);

-- Eliminar usuario de auth.users si existe
DELETE FROM auth.users WHERE email = 'jeysson_s.r@hotmail.com';

-- Verificar limpieza
SELECT 'Usuario limpiado exitosamente' as status;
SELECT COUNT(*) as usuarios_restantes FROM auth.users WHERE email = 'jeysson_s.r@hotmail.com';
SELECT COUNT(*) as perfiles_restantes FROM profiles WHERE email = 'jeysson_s.r@hotmail.com'