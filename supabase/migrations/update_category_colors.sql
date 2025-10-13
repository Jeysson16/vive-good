-- Actualizar colores de categorías para que cada una tenga un color único
-- Esto corrige el problema donde todas las categorías aparecen verdes en los gráficos

-- Actualizar colores específicos por categoría
UPDATE categories 
SET color = '#4CAF50' 
WHERE name = 'Alimentación';

UPDATE categories 
SET color = '#2196F3' 
WHERE name = 'Actividad Física';

UPDATE categories 
SET color = '#9C27B0' 
WHERE name = 'Sueño';

UPDATE categories 
SET color = '#00BCD4' 
WHERE name = 'Hidratación';

UPDATE categories 
SET color = '#FF9800' 
WHERE name = 'Bienestar Mental';

UPDATE categories 
SET color = '#795548' 
WHERE name = 'Productividad';

-- Para cualquier categoría que no coincida con las anteriores, asignar colores alternativos
UPDATE categories 
SET color = CASE 
    WHEN name ILIKE '%ejercicio%' OR name ILIKE '%deporte%' THEN '#2196F3'
    WHEN name ILIKE '%descanso%' OR name ILIKE '%dormir%' THEN '#9C27B0'
    WHEN name ILIKE '%agua%' OR name ILIKE '%beber%' THEN '#00BCD4'
    WHEN name ILIKE '%estrés%' OR name ILIKE '%mental%' OR name ILIKE '%meditación%' THEN '#FF9800'
    WHEN name ILIKE '%trabajo%' OR name ILIKE '%estudio%' THEN '#795548'
    WHEN name ILIKE '%medicina%' OR name ILIKE '%salud%' THEN '#F44336'
    ELSE '#607D8B'
END
WHERE color = '#4CAF50' AND name NOT IN ('Alimentación');

-- Verificar los cambios
SELECT name, color, icon FROM categories ORDER BY name;