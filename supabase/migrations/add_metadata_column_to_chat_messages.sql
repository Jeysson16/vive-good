-- Agregar columna metadata a la tabla chat_messages
-- Esta columna almacenará información adicional sobre los mensajes en formato JSON

ALTER TABLE chat_messages 
ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';

-- Crear índice para mejorar el rendimiento de consultas en metadata
CREATE INDEX IF NOT EXISTS idx_chat_messages_metadata 
ON chat_messages USING GIN (metadata);

-- Comentario para documentar la columna
COMMENT ON COLUMN chat_messages.metadata IS 'Información adicional del mensaje en formato JSON (análisis, métricas, etc.)';