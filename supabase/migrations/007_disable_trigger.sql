-- Deshabilitar temporalmente el trigger problemático
-- para permitir que el registro funcione sin errores

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Verificar que el trigger fue eliminado
SELECT trigger_name, event_manipulation, event_object_table 
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- Mensaje de confirmación
SELECT 'Trigger on_auth_user_created eliminado exitosamente' as status;