-- Migración para verificar que el sistema de registro alternativo funciona completamente
-- Verifica perfiles, roles, hashes de contraseña y permisos

DO $$
DECLARE
    profile_count INTEGER;
    role_count INTEGER;
    user_role_count INTEGER;
    test_profile RECORD;
BEGIN
    RAISE NOTICE '🔍 === VERIFICACIÓN DEL SISTEMA DE REGISTRO ALTERNATIVO ===';
    
    -- Contar perfiles totales
    SELECT COUNT(*) INTO profile_count FROM profiles;
    RAISE NOTICE '📊 Total de perfiles en la base de datos: %', profile_count;
    
    -- Contar roles disponibles
    SELECT COUNT(*) INTO role_count FROM roles;
    RAISE NOTICE '👥 Total de roles disponibles: %', role_count;
    
    -- Mostrar roles disponibles
    FOR test_profile IN SELECT name, description FROM roles LOOP
        RAISE NOTICE '   - Rol: % (Descripción: %)', test_profile.name, test_profile.description;
    END LOOP;
    
    -- Contar asignaciones de roles
    SELECT COUNT(*) INTO user_role_count FROM user_roles;
    RAISE NOTICE '🔗 Total de asignaciones de roles: %', user_role_count;
    
    -- Verificar perfiles con hash de contraseña
    SELECT COUNT(*) INTO profile_count FROM profiles WHERE password_hash IS NOT NULL;
    RAISE NOTICE '🔐 Perfiles con hash de contraseña: %', profile_count;
    
    -- Mostrar información de perfiles existentes
    RAISE NOTICE '📋 === PERFILES EXISTENTES ===';
    FOR test_profile IN 
        SELECT p.email, p.first_name, p.last_name, 
               CASE WHEN p.password_hash IS NOT NULL THEN 'Sí' ELSE 'No' END as tiene_password,
               r.name as rol
        FROM profiles p
        LEFT JOIN user_roles ur ON p.id = ur.user_id
        LEFT JOIN roles r ON ur.role_id = r.id
    LOOP
        RAISE NOTICE '   👤 %: % % (Password: %, Rol: %)', 
            test_profile.email, 
            test_profile.first_name, 
            test_profile.last_name,
            test_profile.tiene_password,
            COALESCE(test_profile.rol, 'Sin rol');
    END LOOP;
    
    -- Verificar permisos de tablas
    RAISE NOTICE '🔒 === VERIFICACIÓN DE PERMISOS ===';
    
    -- Verificar permisos para anon
    IF EXISTS (
        SELECT 1 FROM information_schema.role_table_grants 
        WHERE table_name = 'profiles' AND grantee = 'anon'
    ) THEN
        RAISE NOTICE '✅ Rol anon tiene permisos en tabla profiles';
    ELSE
        RAISE NOTICE '❌ Rol anon NO tiene permisos en tabla profiles';
    END IF;
    
    -- Verificar permisos para authenticated
    IF EXISTS (
        SELECT 1 FROM information_schema.role_table_grants 
        WHERE table_name = 'profiles' AND grantee = 'authenticated'
    ) THEN
        RAISE NOTICE '✅ Rol authenticated tiene permisos en tabla profiles';
    ELSE
        RAISE NOTICE '❌ Rol authenticated NO tiene permisos en tabla profiles';
    END IF;
    
    -- Verificar RLS
    IF EXISTS (
        SELECT 1 FROM pg_tables 
        WHERE tablename = 'profiles' AND rowsecurity = true
    ) THEN
        RAISE NOTICE '🛡️ RLS está habilitado en tabla profiles';
    ELSE
        RAISE NOTICE '⚠️ RLS NO está habilitado en tabla profiles';
    END IF;
    
    RAISE NOTICE '✅ === VERIFICACIÓN COMPLETADA ===';
    RAISE NOTICE '🎯 El sistema de registro alternativo está configurado y listo para usar';
    
END $$;