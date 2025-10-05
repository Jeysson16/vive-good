-- Migración para eliminar la tabla conversations y sus dependencias
-- Esta migración limpia el esquema para usar únicamente chat_sessions

-- Eliminar funciones relacionadas con conversations si existen
DROP FUNCTION IF EXISTS handle_new_conversation() CASCADE;
DROP FUNCTION IF EXISTS update_conversation_updated_at() CASCADE;
DROP FUNCTION IF EXISTS get_conversation_messages(uuid) CASCADE;
DROP FUNCTION IF EXISTS create_conversation_with_message(text, text, text) CASCADE;

-- Eliminar triggers relacionados con conversations si existen
DROP TRIGGER IF EXISTS on_conversation_created ON conversations;
DROP TRIGGER IF EXISTS on_conversation_updated ON conversations;

-- Eliminar políticas RLS de conversations si existen
DROP POLICY IF EXISTS "Users can view own conversations" ON conversations;
DROP POLICY IF EXISTS "Users can insert own conversations" ON conversations;
DROP POLICY IF EXISTS "Users can update own conversations" ON conversations;
DROP POLICY IF EXISTS "Users can delete own conversations" ON conversations;

-- Eliminar índices relacionados con conversations si existen
DROP INDEX IF EXISTS idx_conversations_user_id;
DROP INDEX IF EXISTS idx_conversations_created_at;
DROP INDEX IF EXISTS idx_conversations_updated_at;

-- Eliminar la tabla conversations y todas sus dependencias
DROP TABLE IF EXISTS conversations CASCADE;

-- Comentario de confirmación
-- La tabla conversations ha sido eliminada exitosamente
-- El sistema ahora usa únicamente chat_sessions para el historial de chats