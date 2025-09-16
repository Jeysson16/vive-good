-- Migración para probar el método alternativo de registro
-- Esta migración simula el proceso que debería hacer el método alternativo

DO $$
DECLARE
    test_user_id UUID;
    test_email TEXT := 'test_alternative@example.com';
    test_password_hash TEXT;
    user_role_id UUID;
BEGIN
    -- Generar un ID único para el usuario de prueba
    test_user_id := gen_random_uuid();
    
    -- Simular hash de contraseña (en la app real se usa crypto.sha256)
    test_password_hash := encode(digest('test_password_123', 'sha256'), 'hex');
    
    -- Obtener el ID del rol 'user'
    SELECT id INTO user_role_id FROM roles WHERE name = 'user' LIMIT 1;
    
    -- Verificar si el usuario ya existe
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE email = test_email) THEN
        -- Crear perfil de usuario
        INSERT INTO profiles (id, first_name, last_name, email, password_hash)
        VALUES (
            test_user_id,
            'Test',
            'Alternative',
            test_email,
            test_password_hash
        );
        
        -- Asignar rol de usuario
        IF user_role_id IS NOT NULL THEN
            INSERT INTO user_roles (user_id, role_id)
            VALUES (test_user_id, user_role_id);
        END IF;
        
        RAISE NOTICE '✅ Usuario de prueba creado exitosamente: %', test_email;
        RAISE NOTICE '📋 ID del usuario: %', test_user_id;
        RAISE NOTICE '🔐 Hash de contraseña: %', test_password_hash;
    ELSE
        RAISE NOTICE '⚠️ Usuario ya existe: %', test_email;
    END IF;
    
    -- Verificar la creación
    RAISE NOTICE '📊 Verificando datos creados:';
    
    -- Contar usuarios en profiles
    RAISE NOTICE 'Total de perfiles: %', (SELECT COUNT(*) FROM profiles);
    
    -- Verificar el usuario específico
    IF EXISTS (SELECT 1 FROM profiles WHERE email = test_email) THEN
        RAISE NOTICE '✅ Perfil encontrado para: %', test_email;
    ELSE
        RAISE NOTICE '❌ Perfil NO encontrado para: %', test_email;
    END IF;
    
    -- Verificar rol asignado
    IF EXISTS (
        SELECT 1 FROM user_roles ur 
        JOIN profiles p ON ur.user_id = p.id 
        WHERE p.email = test_email
    ) THEN
        RAISE NOTICE '✅ Rol asignado correctamente';
    ELSE
        RAISE NOTICE '❌ Rol NO asignado';
    END IF;
    
END $$;