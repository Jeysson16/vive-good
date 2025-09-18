-- Extender tabla de perfiles con campos adicionales para la vista de perfil
-- Basado en el diseño Figma Profile (2070_589)

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS age INTEGER;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS institution VARCHAR(255) DEFAULT 'UCV';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS profile_image_url TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS phone VARCHAR(20);

-- Datos de salud
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS height_cm DECIMAL(5,2); -- Altura en centímetros (ej: 172.00)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS weight_kg DECIMAL(5,2); -- Peso en kilogramos (ej: 68.50)

-- Factores de riesgo (array de strings)
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS risk_factors TEXT[] DEFAULT '{}';

-- Hábitos activos con progreso
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS hydration_progress INTEGER DEFAULT 0; -- Días completados
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS hydration_goal INTEGER DEFAULT 5; -- Meta de días
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS sleep_progress INTEGER DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS sleep_goal INTEGER DEFAULT 5;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS activity_progress INTEGER DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS activity_goal INTEGER DEFAULT 5;

-- Configuraciones inteligentes
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS auto_suggestions_enabled BOOLEAN DEFAULT true;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS morning_reminder_time TIME DEFAULT '08:00:00';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS evening_reminder_time TIME DEFAULT '21:30:00';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS daily_reminders_enabled BOOLEAN DEFAULT true;

-- Metadatos adicionales
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_profile_complete BOOLEAN DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_profile_update TIMESTAMP WITH TIME ZONE DEFAULT now();

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_complete ON profiles(is_profile_complete);

-- Función para actualizar last_profile_update automáticamente
CREATE OR REPLACE FUNCTION update_profile_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_profile_update = now();
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar timestamp automáticamente
DROP TRIGGER IF EXISTS trigger_update_profile_timestamp ON profiles;
CREATE TRIGGER trigger_update_profile_timestamp
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_profile_timestamp();

-- Comentarios para documentar la estructura
COMMENT ON COLUMN profiles.age IS 'Edad del usuario en años';
COMMENT ON COLUMN profiles.institution IS 'Institución educativa del usuario';
COMMENT ON COLUMN profiles.height_cm IS 'Altura del usuario en centímetros';
COMMENT ON COLUMN profiles.weight_kg IS 'Peso del usuario en kilogramos';
COMMENT ON COLUMN profiles.risk_factors IS 'Array de factores de riesgo del usuario';
COMMENT ON COLUMN profiles.hydration_progress IS 'Días completados del hábito de hidratación';
COMMENT ON COLUMN profiles.auto_suggestions_enabled IS 'Si las sugerencias automáticas están habilitadas';
COMMENT ON COLUMN profiles.morning_reminder_time IS 'Hora del recordatorio matutino';
COMMENT ON COLUMN profiles.evening_reminder_time IS 'Hora del recordatorio nocturno';
COMMENT ON COLUMN profiles.is_profile_complete IS 'Indica si el perfil del usuario está completo';