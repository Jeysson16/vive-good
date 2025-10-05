-- Agregar columna is_active a la tabla conversations existente

ALTER TABLE conversations ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Crear índice para la nueva columna
CREATE INDEX IF NOT EXISTS idx_conversations_is_active ON conversations(is_active);

-- Actualizar registros existentes para que tengan is_active = true
UPDATE conversations SET is_active = true WHERE is_active IS NULL;