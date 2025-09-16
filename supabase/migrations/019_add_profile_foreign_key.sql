-- Agregar clave foránea faltante entre user_roles y profiles
-- Esto permitirá las consultas con joins entre estas tablas

-- Primero verificar si ya existe la clave foránea
DO $$
BEGIN
    -- Verificar si la constraint ya existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'user_roles_user_id_profiles_fkey'
        AND table_name = 'user_roles'
        AND constraint_type = 'FOREIGN KEY'
    ) THEN
        -- Agregar la clave foránea que conecta user_roles.user_id con profiles.id
        ALTER TABLE user_roles 
        ADD CONSTRAINT user_roles_user_id_profiles_fkey 
        FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;
        
        RAISE NOTICE 'Clave foránea user_roles_user_id_profiles_fkey agregada exitosamente';
    ELSE
        RAISE NOTICE 'La clave foránea user_roles_user_id_profiles_fkey ya existe';
    END IF;
END
$$;

-- Verificar que los datos existentes sean consistentes
-- Eliminar registros huérfanos en user_roles que no tengan perfil correspondiente
DELETE FROM user_roles 
WHERE user_id NOT IN (SELECT id FROM profiles);

-- Mostrar información de las relaciones
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'user_roles'
    AND tc.table_schema = 'public';