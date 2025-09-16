-- Reemplazar la función handle_new_user con una versión más simple
-- que evite problemas de permisos RLS

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    default_role_id UUID;
BEGIN
    -- Obtener el ID del rol 'user' por defecto
    SELECT id INTO default_role_id FROM roles WHERE name = 'user';
    
    -- Insertar perfil usando SECURITY DEFINER para evitar problemas RLS
    INSERT INTO public.profiles (id, first_name, last_name, email)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'first_name', 'Usuario'),
        COALESCE(NEW.raw_user_meta_data->>'last_name', 'Nuevo'),
        NEW.email
    );
    
    -- Asignar rol por defecto
    IF default_role_id IS NOT NULL THEN
        INSERT INTO public.user_roles (user_id, role_id)
        VALUES (NEW.id, default_role_id);
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log del error para debugging
        RAISE LOG 'Error en handle_new_user: %', SQLERRM;
        RETURN NEW; -- Continuar aunque falle
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Asegurar que la función tenga los permisos correctos
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO authenticated, anon;

-- Verificar que el trigger existe
SELECT trigger_name, event_manipulation, event_object_table 
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';