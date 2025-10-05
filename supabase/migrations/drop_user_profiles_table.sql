-- Drop the duplicate user_profiles table
-- All references have been updated to use the 'profiles' table instead

DROP TABLE IF EXISTS user_profiles;

-- Add comment to document the change
COMMENT ON TABLE profiles IS 'Main user profiles table - consolidated from user_profiles';