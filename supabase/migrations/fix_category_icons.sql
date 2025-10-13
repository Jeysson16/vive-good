-- Actualizar iconos de categorías para que muestren iconos específicos en lugar de 'heart'
-- Esto corrige el problema donde todas las categorías muestran el mismo icono

-- Actualizar iconos específicos por categoría
UPDATE categories 
SET icon = 'restaurant' 
WHERE name = 'Alimentación';

UPDATE categories 
SET icon = 'fitness_center' 
WHERE name = 'Actividad Física';

UPDATE categories 
SET icon = 'bedtime' 
WHERE name = 'Sueño';

UPDATE categories 
SET icon = 'water_drop' 
WHERE name = 'Hidratación';

UPDATE categories 
SET icon = 'psychology' 
WHERE name = 'Bienestar Mental';

UPDATE categories 
SET icon = 'track_changes' 
WHERE name = 'Productividad';

-- Para cualquier categoría que no coincida con las anteriores, asignar iconos alternativos
UPDATE categories 
SET icon = CASE 
    WHEN name ILIKE '%ejercicio%' OR name ILIKE '%deporte%' OR name ILIKE '%físic%' THEN 'fitness_center'
    WHEN name ILIKE '%descanso%' OR name ILIKE '%dormir%' OR name ILIKE '%sueño%' THEN 'bedtime'
    WHEN name ILIKE '%agua%' OR name ILIKE '%beber%' OR name ILIKE '%hidrat%' THEN 'water_drop'
    WHEN name ILIKE '%estrés%' OR name ILIKE '%mental%' OR name ILIKE '%meditación%' OR name ILIKE '%bienestar%' THEN 'psychology'
    WHEN name ILIKE '%trabajo%' OR name ILIKE '%estudio%' OR name ILIKE '%productiv%' THEN 'track_changes'
    WHEN name ILIKE '%comida%' OR name ILIKE '%alimenta%' OR name ILIKE '%nutri%' THEN 'restaurant'
    WHEN name ILIKE '%medicina%' OR name ILIKE '%salud%' THEN 'local_hospital'
    ELSE 'star'
END
WHERE icon = 'heart' AND name NOT IN ('Alimentación', 'Actividad Física', 'Sueño', 'Hidratación', 'Bienestar Mental', 'Productividad');

-- Verificar los cambios
SELECT name, icon, color FROM categories ORDER BY name;