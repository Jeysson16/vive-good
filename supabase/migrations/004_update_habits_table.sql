-- Actualizar tabla habits para incluir campos faltantes que espera el stored procedure

-- Agregar columnas faltantes a la tabla habits
ALTER TABLE habits ADD COLUMN IF NOT EXISTS icon_name VARCHAR(50) DEFAULT 'star';
ALTER TABLE habits ADD COLUMN IF NOT EXISTS icon_color VARCHAR(20) DEFAULT '#4CAF50';
ALTER TABLE habits ADD COLUMN IF NOT EXISTS difficulty_level VARCHAR(20) DEFAULT 'easy';
ALTER TABLE habits ADD COLUMN IF NOT EXISTS estimated_duration INTEGER DEFAULT 15; -- en minutos
ALTER TABLE habits ADD COLUMN IF NOT EXISTS benefits TEXT[] DEFAULT '{}';
ALTER TABLE habits ADD COLUMN IF NOT EXISTS tips TEXT[] DEFAULT '{}';
ALTER TABLE habits ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- Actualizar hábitos existentes con valores por defecto
UPDATE habits SET 
    icon_name = CASE 
        WHEN name LIKE '%agua%' OR name LIKE '%beber%' THEN 'local_drink'
        WHEN name LIKE '%fruta%' OR name LIKE '%comer%' THEN 'apple'
        WHEN name LIKE '%almuerzo%' OR name LIKE '%comida%' THEN 'restaurant'
        WHEN name LIKE '%caminar%' OR name LIKE '%ejercicio%' THEN 'directions_walk'
        WHEN name LIKE '%estiramiento%' THEN 'accessibility_new'
        WHEN name LIKE '%dormir%' OR name LIKE '%sueño%' THEN 'bedtime'
        WHEN name LIKE '%pantalla%' THEN 'phone_iphone'
        WHEN name LIKE '%meditar%' THEN 'self_improvement'
        WHEN name LIKE '%diario%' OR name LIKE '%escribir%' THEN 'edit'
        WHEN name LIKE '%leer%' THEN 'menu_book'
        WHEN name LIKE '%planificar%' THEN 'event_note'
        ELSE 'star'
    END,
    icon_color = CASE 
        WHEN category_id = (SELECT id FROM categories WHERE name = 'Hidratación') THEN '#00BCD4'
        WHEN category_id = (SELECT id FROM categories WHERE name = 'Alimentación') THEN '#4CAF50'
        WHEN category_id = (SELECT id FROM categories WHERE name = 'Actividad Física') THEN '#2196F3'
        WHEN category_id = (SELECT id FROM categories WHERE name = 'Sueño') THEN '#9C27B0'
        WHEN category_id = (SELECT id FROM categories WHERE name = 'Bienestar Mental') THEN '#FF9800'
        WHEN category_id = (SELECT id FROM categories WHERE name = 'Productividad') THEN '#795548'
        ELSE '#4CAF50'
    END,
    difficulty_level = CASE 
        WHEN name LIKE '%30 minutos%' OR name LIKE '%ejercicio%' THEN 'medium'
        WHEN name LIKE '%8 horas%' OR name LIKE '%dormir%' THEN 'medium'
        WHEN name LIKE '%meditar%' OR name LIKE '%planificar%' THEN 'easy'
        ELSE 'easy'
    END,
    estimated_duration = CASE 
        WHEN name LIKE '%30 minutos%' THEN 30
        WHEN name LIKE '%10 minutos%' THEN 10
        WHEN name LIKE '%20 páginas%' THEN 25
        WHEN name LIKE '%agua%' OR name LIKE '%beber%' THEN 2
        WHEN name LIKE '%almuerzo%' THEN 30
        ELSE 15
    END,
    benefits = CASE 
        WHEN name LIKE '%agua%' THEN ARRAY['Mejora la hidratación', 'Aumenta la energía', 'Mejora la concentración']
        WHEN name LIKE '%fruta%' THEN ARRAY['Aporta vitaminas', 'Mejora la digestión', 'Aumenta la energía']
        WHEN name LIKE '%ejercicio%' OR name LIKE '%caminar%' THEN ARRAY['Mejora la salud cardiovascular', 'Aumenta la resistencia', 'Reduce el estrés']
        WHEN name LIKE '%dormir%' THEN ARRAY['Mejora la recuperación', 'Aumenta la concentración', 'Fortalece el sistema inmune']
        WHEN name LIKE '%meditar%' THEN ARRAY['Reduce el estrés', 'Mejora la concentración', 'Aumenta la paz mental']
        WHEN name LIKE '%leer%' THEN ARRAY['Expande el conocimiento', 'Mejora la concentración', 'Estimula la creatividad']
        ELSE ARRAY['Mejora el bienestar general']
    END,
    tips = CASE 
        WHEN name LIKE '%agua%' THEN ARRAY['Lleva una botella contigo', 'Pon alarmas como recordatorio', 'Agrega limón para sabor']
        WHEN name LIKE '%fruta%' THEN ARRAY['Prepara las frutas la noche anterior', 'Varía los tipos de fruta', 'Combina con yogur']
        WHEN name LIKE '%ejercicio%' OR name LIKE '%caminar%' THEN ARRAY['Empieza gradualmente', 'Encuentra un compañero', 'Escucha música motivadora']
        WHEN name LIKE '%dormir%' THEN ARRAY['Mantén horarios regulares', 'Evita cafeína por la tarde', 'Crea un ambiente relajante']
        WHEN name LIKE '%meditar%' THEN ARRAY['Empieza con 5 minutos', 'Usa aplicaciones guiadas', 'Encuentra un lugar tranquilo']
        WHEN name LIKE '%leer%' THEN ARRAY['Lleva un libro contigo', 'Lee antes de dormir', 'Únete a un club de lectura']
        ELSE ARRAY['Sé constante', 'Empieza poco a poco']
    END
WHERE icon_name IS NULL OR icon_name = 'heart' OR icon_name = 'star';

-- Crear índice para mejorar el rendimiento de las consultas
CREATE INDEX IF NOT EXISTS idx_habits_is_active ON habits(is_active);
CREATE INDEX IF NOT EXISTS idx_habits_difficulty_level ON habits(difficulty_level);

-- Comentario
COMMENT ON COLUMN habits.icon_name IS 'Nombre del icono Material Design para mostrar en la UI';
COMMENT ON COLUMN habits.icon_color IS 'Color hexadecimal del icono';
COMMENT ON COLUMN habits.difficulty_level IS 'Nivel de dificultad: easy, medium, hard';
COMMENT ON COLUMN habits.estimated_duration IS 'Duración estimada en minutos';
COMMENT ON COLUMN habits.benefits IS 'Array de beneficios del hábito';
COMMENT ON COLUMN habits.tips IS 'Array de consejos para el hábito';
COMMENT ON COLUMN habits.is_active IS 'Si el hábito está activo y disponible para sugerencias';