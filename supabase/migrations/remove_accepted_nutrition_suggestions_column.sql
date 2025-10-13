-- Remove the accepted_nutrition_suggestions column from user_progress table
-- This column is no longer used and is causing errors in the stored procedures

-- Remove the column from user_progress table
ALTER TABLE user_progress DROP COLUMN IF EXISTS accepted_nutrition_suggestions;

-- Add comment
COMMENT ON TABLE user_progress IS 'User progress tracking table without nutrition suggestions field';