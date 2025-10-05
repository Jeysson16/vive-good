-- Agregar columna title faltante a la tabla conversations
-- Esta migración corrige el esquema para incluir la columna title requerida por el código

ALTER TABLE conversations ADD COLUMN IF NOT EXISTS title VARCHAR(255) DEFAULT 'Nueva conversación';

-- Actualizar registros existentes que no tengan título
UPDATE conversations SET title = 'Nueva conversación' WHERE title IS NULL;

-- Crear índice para mejorar búsquedas por título
CREATE INDEX IF NOT EXISTS idx_conversations_title ON conversations(title);