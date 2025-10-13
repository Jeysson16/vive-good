-- Execute cleanup of duplicate user_habits
SELECT * FROM clean_duplicate_user_habits();

-- Verify integrity after cleanup
SELECT * FROM verify_user_habits_integrity();