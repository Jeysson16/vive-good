-- Agregar campo password_hash a la tabla profiles para método alternativo
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS password_hash TEXT;

-- Verificar que el campo fue agregado
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profiles' AND column_name = 'password_hash';

SELECT 'Campo password_hash agregado exitosamente' as status;