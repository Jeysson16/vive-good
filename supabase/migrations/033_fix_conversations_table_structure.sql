-- Corregir la estructura de la tabla conversations
-- Eliminar campos message y response que no son necesarios y causan errores

-- Los campos message y response no son necesarios en la tabla conversations
-- ya que los mensajes se almacenan en la tabla messages separada
ALTER TABLE conversations DROP COLUMN IF EXISTS message;
ALTER TABLE conversations DROP COLUMN IF EXISTS response;
ALTER TABLE conversations DROP COLUMN IF EXISTS intent;
ALTER TABLE conversations DROP COLUMN IF EXISTS confidence;
ALTER TABLE conversations DROP COLUMN IF EXISTS context;

-- Asegurar que la tabla tenga la estructura correcta
-- Añadir columnas que faltan si no existen
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS content TEXT;
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Verificar que los índices existan
CREATE INDEX IF NOT EXISTS idx_conversations_user_id ON conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_conversations_created_at ON conversations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversations_is_active ON conversations(is_active);

-- Asegurar que el trigger de updated_at exista
DROP TRIGGER IF EXISTS update_conversations_updated_at ON conversations;
CREATE TRIGGER update_conversations_updated_at BEFORE UPDATE ON conversations
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Verificar permisos
GRANT ALL PRIVILEGES ON conversations TO authenticated;
GRANT SELECT ON conversations TO anon;