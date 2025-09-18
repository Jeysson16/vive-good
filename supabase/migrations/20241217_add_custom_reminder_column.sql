-- Add custom_reminder column to user_habits table
ALTER TABLE public.user_habits 
ADD COLUMN custom_reminder TEXT;

-- Add comment to the column
COMMENT ON COLUMN public.user_habits.custom_reminder IS 'Custom reminder text for the habit';