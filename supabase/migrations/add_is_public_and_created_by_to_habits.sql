-- Add is_public field to habits table
ALTER TABLE habits 
ADD COLUMN is_public BOOLEAN DEFAULT true;

-- Add comment to the new column
COMMENT ON COLUMN habits.is_public IS 'Indicates if the habit is public (visible to all users) or private (custom habit)';

-- Create index for better performance on queries
CREATE INDEX idx_habits_is_public ON habits(is_public);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON habits TO authenticated;
GRANT SELECT ON habits TO anon;

-- Update existing habits to be public (official habits)
UPDATE habits SET is_public = true WHERE created_by IS NULL;