-- Drop conversations table and use chat_sessions/chat_messages instead
-- This migration removes the problematic conversations table that has NOT NULL constraints
-- causing issues when creating new conversations

-- Drop the conversations table and all its dependencies
DROP TABLE IF EXISTS conversations CASCADE;

-- Drop any functions or triggers related to conversations
DROP FUNCTION IF EXISTS update_conversations_updated_at() CASCADE;
DROP TRIGGER IF EXISTS update_conversations_updated_at_trigger ON conversations;

-- Ensure chat_sessions and chat_messages tables exist and are properly configured
-- (These should already exist from migration 020_create_chat_system.sql)

-- Add any missing indexes for better performance
CREATE INDEX IF NOT EXISTS idx_chat_sessions_user_id ON chat_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_created_at ON chat_sessions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_session_id ON chat_messages(session_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at DESC);

-- Ensure RLS policies are enabled
ALTER TABLE chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Grant necessary permissions
GRANT ALL PRIVILEGES ON chat_sessions TO authenticated;
GRANT ALL PRIVILEGES ON chat_messages TO authenticated;
GRANT SELECT ON chat_sessions TO anon;
GRANT SELECT ON chat_messages TO anon;