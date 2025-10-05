-- Migración para eliminar la tabla conversations y sus dependencias
-- Fecha: 2024-12-20
-- Descripción: Elimina la tabla conversations ya que se usa chat_sessions para el historial

-- Eliminar funciones relacionadas con conversations si existen
DROP FUNCTION IF EXISTS get_conversation_history(text);
DROP FUNCTION IF EXISTS create_conversation(text, text);
DROP FUNCTION IF EXISTS update_conversation_summary(text, text);

-- Eliminar triggers relacionados con conversations si existen
DROP TRIGGER IF EXISTS update_conversations_updated_at ON conversations;

-- Eliminar la tabla conversations y todas sus dependencias
DROP TABLE IF EXISTS conversations CASCADE;

-- Verificar que las tablas de chat_sessions y chat_messages existen y están correctamente configuradas
-- (No las creamos aquí porque ya existen)

-- Comentario: La funcionalidad de historial de conversaciones ahora se maneja
-- completamente a través de las tablas chat_sessions y chat_messages