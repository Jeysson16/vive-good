-- Migración para renombrar columnas de profiles a inglés
-- Cambiar nombres y apellidos por first_name y last_name

ALTER TABLE profiles 
RENAME COLUMN nombres TO first_name;

ALTER TABLE profiles 
RENAME COLUMN apellidos TO last_name;

-- Actualizar función handle_new_user para usar los nuevos nombres de columnas
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    default_role_id UUID;
BEGIN
    -- Obtener el ID del rol 'user' por defecto
    SELECT id INTO default_role_id FROM roles WHERE name = 'user';
    
    -- Insertar perfil con nombres en inglés
    INSERT INTO public.profiles (id, first_name, last_name, email)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
        NEW.email
    );
    
    -- Asignar rol por defecto
    INSERT INTO public.user_roles (user_id, role_id)
    VALUES (NEW.id, default_role_id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;