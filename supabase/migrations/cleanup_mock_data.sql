-- Remove problematic mock data with invalid user_id
DELETE FROM public.user_progress 
WHERE user_id = '00000000-0000-0000-0000-000000000000';

-- Add unique constraint on user_id to prevent duplicates
ALTER TABLE public.user_progress 
ADD CONSTRAINT unique_user_progress_user_id UNIQUE (user_id);