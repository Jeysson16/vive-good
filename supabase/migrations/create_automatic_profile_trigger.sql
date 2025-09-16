-- Crear trigger automático para crear perfiles cuando se registra un usuario
-- Esto evita problemas de contexto de autenticación durante el registro

-- Primero, asegurar que RLS esté deshabilitado para profiles
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;

-- Eliminar trigger existente si existe
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Crear función para manejar nuevos usuarios
CREate OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    default_role_id UUID;
BEGIN
    -- Obtener el ID del rol 'user' por defecto
    SELECT id INTO default_role_id FROM roles WHERE name = 'user';
    
    -- Insertar perfil básico (sin first_name y last_name por ahora)
    INSERT INTO public.profiles (id, email, first_name, last_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'last_name', '')
    );
    
    -- Asignar rol por defecto si existe
    IF default_role_id IS NOT NULL THEN
        INSERT INTO public.user_roles (user_id, role_id)
        VALUES (NEW.id, default_role_id)
        ON CONFLICT (user_id, role_id) DO NOTHING;
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log del error pero no fallar el registro
        RAISE WARNING 'Error al crear perfil automático: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Crear trigger que se ejecuta cuando se crea un usuario en auth.users
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Verificar que el trigger se creó correctamente
SELECT 'Trigger automático creado para perfiles' as resultado;

-- Mostrar triggers existentes
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';