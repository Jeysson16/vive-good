-- Create message_feedback table to store user feedback on chat messages
CREATE TABLE IF NOT EXISTS message_feedback (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    message_id UUID NOT NULL REFERENCES chat_messages(id) ON DELETE CASCADE,
    feedback_type VARCHAR(10) NOT NULL CHECK (feedback_type IN ('like', 'dislike')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure one feedback per user per message
    UNIQUE(user_id, message_id)
);

-- Enable RLS
ALTER TABLE message_feedback ENABLE ROW LEVEL SECURITY;

-- Create policies for message_feedback
CREATE POLICY "Users can view their own message feedback" ON message_feedback
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own message feedback" ON message_feedback
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own message feedback" ON message_feedback
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own message feedback" ON message_feedback
    FOR DELETE USING (auth.uid() = user_id);

-- Grant permissions to authenticated users
GRANT ALL PRIVILEGES ON message_feedback TO authenticated;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_message_feedback_user_id ON message_feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_message_feedback_message_id ON message_feedback(message_id);
CREATE INDEX IF NOT EXISTS idx_message_feedback_type ON message_feedback(feedback_type);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_message_feedback_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER trigger_update_message_feedback_updated_at
    BEFORE UPDATE ON message_feedback
    FOR EACH ROW
    EXECUTE FUNCTION update_message_feedback_updated_at();