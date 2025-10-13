-- Add metadata column to chat_messages table
ALTER TABLE chat_messages 
ADD COLUMN metadata JSONB DEFAULT NULL;

-- Add comment to explain the metadata column
COMMENT ON COLUMN chat_messages.metadata IS 'JSON metadata for storing additional message information like suggested habits';