-- Corregir tabla conversations para asegurar que updated_at funcione correctamente

-- Verificar si la función update_updated_at_column existe, si no, crearla
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Asegurar que la columna updated_at existe
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Eliminar el trigger existente si existe para evitar duplicados
DROP TRIGGER IF EXISTS update_conversations_updated_at ON conversations;

-- Crear el trigger para actualizar updated_at
CREATE TRIGGER update_conversations_updated_at 
    BEFORE UPDATE ON conversations
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Actualizar registros existentes que no tengan updated_at
UPDATE conversations 
SET updated_at = created_at 
WHERE updated_at IS NULL;

-- Crear índice para updated_at si no existe
CREATE INDEX IF NOT EXISTS idx_conversations_updated_at ON conversations(updated_at DESC);