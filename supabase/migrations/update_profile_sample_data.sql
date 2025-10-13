-- Actualizar el perfil del usuario con datos de ejemplo para mostrar en la interfaz
-- Solo actualiza si los campos están vacíos (NULL)

UPDATE profiles 
SET 
  height_cm = CASE WHEN height_cm IS NULL THEN 175.0 ELSE height_cm END,
  weight_kg = CASE WHEN weight_kg IS NULL THEN 68.0 ELSE weight_kg END,
  age = CASE WHEN age IS NULL THEN 21 ELSE age END,
  hydration_progress = CASE WHEN hydration_progress = 0 THEN 3 ELSE hydration_progress END,
  sleep_progress = CASE WHEN sleep_progress = 0 THEN 4 ELSE sleep_progress END,
  activity_progress = CASE WHEN activity_progress = 0 THEN 2 ELSE activity_progress END,
  risk_factors = CASE 
    WHEN risk_factors = '{}' OR risk_factors IS NULL 
    THEN ARRAY['Come fuera frecuentemente', 'Consume café en ayunas'] 
    ELSE risk_factors 
  END,
  updated_at = NOW()
WHERE first_name = 'Jeysson Manuel' AND last_name = 'Sánchez Rodríguez';