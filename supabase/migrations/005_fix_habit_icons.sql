-- Fix habit icons based on habit names
-- Update existing habits with appropriate icons

UPDATE habits SET 
    icon_name = CASE 
        WHEN LOWER(name) LIKE '%agua%' OR LOWER(name) LIKE '%beber%' OR LOWER(name) LIKE '%hidrat%' THEN 'local_drink'
        WHEN LOWER(name) LIKE '%fruta%' OR LOWER(name) LIKE '%manzana%' OR LOWER(name) LIKE '%apple%' THEN 'apple'
        WHEN LOWER(name) LIKE '%almuerzo%' OR LOWER(name) LIKE '%comida%' OR LOWER(name) LIKE '%comer%' OR LOWER(name) LIKE '%restaurant%' THEN 'restaurant'
        WHEN LOWER(name) LIKE '%caminar%' OR LOWER(name) LIKE '%walk%' OR LOWER(name) LIKE '%paso%' THEN 'directions_walk'
        WHEN LOWER(name) LIKE '%estiramiento%' OR LOWER(name) LIKE '%stretch%' OR LOWER(name) LIKE '%flexibilidad%' THEN 'accessibility_new'
        WHEN LOWER(name) LIKE '%dormir%' OR LOWER(name) LIKE '%sueño%' OR LOWER(name) LIKE '%sleep%' OR LOWER(name) LIKE '%descanso%' THEN 'bedtime'
        WHEN LOWER(name) LIKE '%pantalla%' OR LOWER(name) LIKE '%teléfono%' OR LOWER(name) LIKE '%phone%' OR LOWER(name) LIKE '%móvil%' THEN 'phone_iphone'
        WHEN LOWER(name) LIKE '%meditar%' OR LOWER(name) LIKE '%meditación%' OR LOWER(name) LIKE '%mindfulness%' THEN 'self_improvement'
        WHEN LOWER(name) LIKE '%diario%' OR LOWER(name) LIKE '%escribir%' OR LOWER(name) LIKE '%journal%' OR LOWER(name) LIKE '%write%' THEN 'edit'
        WHEN LOWER(name) LIKE '%leer%' OR LOWER(name) LIKE '%lectura%' OR LOWER(name) LIKE '%libro%' OR LOWER(name) LIKE '%read%' THEN 'menu_book'
        WHEN LOWER(name) LIKE '%planificar%' OR LOWER(name) LIKE '%plan%' OR LOWER(name) LIKE '%organizar%' THEN 'event_note'
        WHEN LOWER(name) LIKE '%ejercicio%' OR LOWER(name) LIKE '%gym%' OR LOWER(name) LIKE '%fitness%' OR LOWER(name) LIKE '%entrenar%' THEN 'fitness_center'
        WHEN LOWER(name) LIKE '%trabajo%' OR LOWER(name) LIKE '%work%' OR LOWER(name) LIKE '%oficina%' THEN 'work'
        WHEN LOWER(name) LIKE '%estudio%' OR LOWER(name) LIKE '%estudiar%' OR LOWER(name) LIKE '%study%' OR LOWER(name) LIKE '%aprender%' THEN 'school'
        WHEN LOWER(name) LIKE '%dinero%' OR LOWER(name) LIKE '%finanzas%' OR LOWER(name) LIKE '%money%' OR LOWER(name) LIKE '%ahorro%' THEN 'attach_money'
        WHEN LOWER(name) LIKE '%casa%' OR LOWER(name) LIKE '%hogar%' OR LOWER(name) LIKE '%home%' OR LOWER(name) LIKE '%limpieza%' THEN 'home'
        WHEN LOWER(name) LIKE '%social%' OR LOWER(name) LIKE '%amigos%' OR LOWER(name) LIKE '%familia%' OR LOWER(name) LIKE '%people%' THEN 'people'
        WHEN LOWER(name) LIKE '%creativ%' OR LOWER(name) LIKE '%arte%' OR LOWER(name) LIKE '%dibujar%' OR LOWER(name) LIKE '%pintar%' THEN 'palette'
        WHEN LOWER(name) LIKE '%espiritual%' OR LOWER(name) LIKE '%orar%' OR LOWER(name) LIKE '%spiritual%' THEN 'self_improvement'
        WHEN LOWER(name) LIKE '%película%' OR LOWER(name) LIKE '%movie%' OR LOWER(name) LIKE '%entretenimiento%' THEN 'movie'
        ELSE 'star'
    END,
    icon_color = CASE 
        WHEN category_id = (SELECT id FROM categories WHERE LOWER(name) LIKE '%hidrat%' OR LOWER(name) LIKE '%agua%') THEN '#00BCD4'
        WHEN category_id = (SELECT id FROM categories WHERE LOWER(name) LIKE '%alimenta%' OR LOWER(name) LIKE '%comida%') THEN '#4CAF50'
        WHEN category_id = (SELECT id FROM categories WHERE LOWER(name) LIKE '%actividad%' OR LOWER(name) LIKE '%ejercicio%' OR LOWER(name) LIKE '%físic%') THEN '#2196F3'
        WHEN category_id = (SELECT id FROM categories WHERE LOWER(name) LIKE '%sueño%' OR LOWER(name) LIKE '%descanso%') THEN '#9C27B0'
        WHEN category_id = (SELECT id FROM categories WHERE LOWER(name) LIKE '%bienestar%' OR LOWER(name) LIKE '%mental%') THEN '#FF9800'
        WHEN category_id = (SELECT id FROM categories WHERE LOWER(name) LIKE '%productividad%' OR LOWER(name) LIKE '%trabajo%') THEN '#795548'
        WHEN category_id = (SELECT id FROM categories WHERE LOWER(name) LIKE '%finanzas%' OR LOWER(name) LIKE '%dinero%') THEN '#4CAF50'
        WHEN category_id = (SELECT id FROM categories WHERE LOWER(name) LIKE '%hogar%' OR LOWER(name) LIKE '%casa%') THEN '#FF5722'
        WHEN category_id = (SELECT id FROM categories WHERE LOWER(name) LIKE '%social%' OR LOWER(name) LIKE '%relacion%') THEN '#E91E63'
        WHEN category_id = (SELECT id FROM categories WHERE LOWER(name) LIKE '%creativ%' OR LOWER(name) LIKE '%arte%') THEN '#9C27B0'
        WHEN category_id = (SELECT id FROM categories WHERE LOWER(name) LIKE '%espiritual%') THEN '#673AB7'
        WHEN category_id = (SELECT id FROM categories WHERE LOWER(name) LIKE '%entretenimiento%') THEN '#FF9800'
        ELSE '#6366F1'
    END
WHERE icon_name = 'heart' OR icon_name IS NULL;

-- Update any remaining habits that still have 'heart' as icon
UPDATE habits SET icon_name = 'star' WHERE icon_name = 'heart';

-- Verify the update
-- SELECT name, icon_name, icon_color FROM habits ORDER BY name;