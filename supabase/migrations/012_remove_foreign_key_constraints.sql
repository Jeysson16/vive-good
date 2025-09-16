-- Migración para eliminar las restricciones de clave foránea que impiden el método alternativo
-- Esto permite crear perfiles sin usuarios en auth.users

-- Eliminar la restricción de clave foránea en profiles
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;

-- Eliminar la restricción de clave foránea en user_roles
ALTER TABLE user_roles DROP CONSTRAINT IF EXISTS user_roles_user_id_fkey;

-- Verificar que las restricciones fueron eliminadas
DO $$
BEGIN
    -- Verificar profiles
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'profiles_id_fkey' 
        AND table_name = 'profiles'
    ) THEN
        RAISE NOTICE '✅ Restricción profiles_id_fkey eliminada correctamente';
    ELSE
        RAISE NOTICE '❌ Error: Restricción profiles_id_fkey aún existe';
    END IF;
    
    -- Verificar user_roles
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'user_roles_user_id_fkey' 
        AND table_name = 'user_roles'
    ) THEN
        RAISE NOTICE '✅ Restricción user_roles_user_id_fkey eliminada correctamente';
    ELSE
        RAISE NOTICE '❌ Error: Restricción user_roles_user_id_fkey aún existe';
    END IF;
    
    RAISE NOTICE '🎯 Ahora se pueden crear perfiles sin usuarios en auth.users';
END $$;