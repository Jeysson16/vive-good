-- Actualizar iconos de hábitos existentes que tienen 'heart' como valor por defecto
-- Esta migración corrige los datos existentes en la tabla habits

-- Actualizar iconos basándose en el nombre y categoría del hábito
UPDATE habits 
SET 
  icon_name = CASE 
    -- Hábitos de ejercicio/fitness
    WHEN LOWER(name) LIKE '%ejercicio%' OR LOWER(name) LIKE '%gym%' OR LOWER(name) LIKE '%correr%' OR LOWER(name) LIKE '%caminar%' THEN 'fitness_center'
    WHEN LOWER(name) LIKE '%yoga%' OR LOWER(name) LIKE '%meditación%' OR LOWER(name) LIKE '%meditar%' THEN 'self_improvement'
    WHEN LOWER(name) LIKE '%natación%' OR LOWER(name) LIKE '%nadar%' THEN 'pool'
    
    -- Hábitos de alimentación
    WHEN LOWER(name) LIKE '%agua%' OR LOWER(name) LIKE '%beber%' OR LOWER(name) LIKE '%hidrat%' THEN 'local_drink'
    WHEN LOWER(name) LIKE '%fruta%' OR LOWER(name) LIKE '%verdura%' OR LOWER(name) LIKE '%vegetal%' OR LOWER(name) LIKE '%ensalada%' THEN 'eco'
    WHEN LOWER(name) LIKE '%desayun%' OR LOWER(name) LIKE '%comer%' OR LOWER(name) LIKE '%comida%' THEN 'restaurant'
    WHEN LOWER(name) LIKE '%vitamina%' OR LOWER(name) LIKE '%suplemento%' THEN 'medication'
    
    -- Hábitos de sueño
    WHEN LOWER(name) LIKE '%dormir%' OR LOWER(name) LIKE '%sueño%' OR LOWER(name) LIKE '%descanso%' THEN 'bedtime'
    WHEN LOWER(name) LIKE '%despertar%' OR LOWER(name) LIKE '%levantarse%' THEN 'alarm'
    
    -- Hábitos de lectura/estudio
    WHEN LOWER(name) LIKE '%leer%' OR LOWER(name) LIKE '%lectura%' OR LOWER(name) LIKE '%libro%' THEN 'menu_book'
    WHEN LOWER(name) LIKE '%estudiar%' OR LOWER(name) LIKE '%estudio%' OR LOWER(name) LIKE '%aprender%' THEN 'school'
    WHEN LOWER(name) LIKE '%escribir%' OR LOWER(name) LIKE '%diario%' OR LOWER(name) LIKE '%journal%' THEN 'edit'
    
    -- Hábitos de trabajo/productividad
    WHEN LOWER(name) LIKE '%trabajo%' OR LOWER(name) LIKE '%oficina%' OR LOWER(name) LIKE '%reunión%' THEN 'work'
    WHEN LOWER(name) LIKE '%planificar%' OR LOWER(name) LIKE '%organizar%' OR LOWER(name) LIKE '%agenda%' THEN 'event_note'
    WHEN LOWER(name) LIKE '%email%' OR LOWER(name) LIKE '%correo%' THEN 'email'
    
    -- Hábitos sociales/familia
    WHEN LOWER(name) LIKE '%familia%' OR LOWER(name) LIKE '%hijo%' OR LOWER(name) LIKE '%padre%' OR LOWER(name) LIKE '%madre%' THEN 'family_restroom'
    WHEN LOWER(name) LIKE '%amigo%' OR LOWER(name) LIKE '%social%' OR LOWER(name) LIKE '%llamar%' THEN 'people'
    
    -- Hábitos de cuidado personal
    WHEN LOWER(name) LIKE '%ducha%' OR LOWER(name) LIKE '%bañar%' OR LOWER(name) LIKE '%higiene%' THEN 'shower'
    WHEN LOWER(name) LIKE '%dientes%' OR LOWER(name) LIKE '%cepillar%' THEN 'clean_hands'
    WHEN LOWER(name) LIKE '%crema%' OR LOWER(name) LIKE '%cuidado%' OR LOWER(name) LIKE '%piel%' THEN 'spa'
    
    -- Hábitos de hogar
    WHEN LOWER(name) LIKE '%limpiar%' OR LOWER(name) LIKE '%limpieza%' OR LOWER(name) LIKE '%ordenar%' THEN 'cleaning_services'
    WHEN LOWER(name) LIKE '%cocinar%' OR LOWER(name) LIKE '%cocina%' THEN 'kitchen'
    WHEN LOWER(name) LIKE '%lavar%' OR LOWER(name) LIKE '%ropa%' THEN 'local_laundry_service'
    
    -- Hábitos financieros
    WHEN LOWER(name) LIKE '%dinero%' OR LOWER(name) LIKE '%ahorrar%' OR LOWER(name) LIKE '%presupuesto%' THEN 'savings'
    WHEN LOWER(name) LIKE '%gasto%' OR LOWER(name) LIKE '%compra%' OR LOWER(name) LIKE '%factura%' THEN 'receipt_long'
    
    -- Hábitos de entretenimiento
    WHEN LOWER(name) LIKE '%música%' OR LOWER(name) LIKE '%cantar%' OR LOWER(name) LIKE '%instrumento%' THEN 'music_note'
    WHEN LOWER(name) LIKE '%película%' OR LOWER(name) LIKE '%serie%' OR LOWER(name) LIKE '%tv%' THEN 'movie'
    WHEN LOWER(name) LIKE '%juego%' OR LOWER(name) LIKE '%videojuego%' THEN 'sports_esports'
    
    -- Hábitos de transporte
    WHEN LOWER(name) LIKE '%caminar%' OR LOWER(name) LIKE '%pasear%' THEN 'directions_walk'
    WHEN LOWER(name) LIKE '%bicicleta%' OR LOWER(name) LIKE '%ciclismo%' THEN 'directions_bike'
    WHEN LOWER(name) LIKE '%coche%' OR LOWER(name) LIKE '%conducir%' THEN 'directions_car'
    
    -- Por defecto, usar un icono genérico basado en la categoría
    ELSE 'star'
  END,
  
  icon_color = CASE 
    -- Colores por categoría de hábito
    WHEN LOWER(name) LIKE '%ejercicio%' OR LOWER(name) LIKE '%gym%' OR LOWER(name) LIKE '%correr%' OR LOWER(name) LIKE '%yoga%' THEN '#FF5722' -- Naranja para fitness
    WHEN LOWER(name) LIKE '%agua%' OR LOWER(name) LIKE '%fruta%' OR LOWER(name) LIKE '%verdura%' OR LOWER(name) LIKE '%comida%' THEN '#4CAF50' -- Verde para alimentación
    WHEN LOWER(name) LIKE '%dormir%' OR LOWER(name) LIKE '%sueño%' OR LOWER(name) LIKE '%descanso%' THEN '#3F51B5' -- Azul para sueño
    WHEN LOWER(name) LIKE '%leer%' OR LOWER(name) LIKE '%estudiar%' OR LOWER(name) LIKE '%escribir%' THEN '#9C27B0' -- Púrpura para educación
    WHEN LOWER(name) LIKE '%trabajo%' OR LOWER(name) LIKE '%oficina%' OR LOWER(name) LIKE '%planificar%' THEN '#607D8B' -- Gris azulado para trabajo
    WHEN LOWER(name) LIKE '%familia%' OR LOWER(name) LIKE '%amigo%' OR LOWER(name) LIKE '%social%' THEN '#E91E63' -- Rosa para social
    WHEN LOWER(name) LIKE '%ducha%' OR LOWER(name) LIKE '%dientes%' OR LOWER(name) LIKE '%cuidado%' THEN '#00BCD4' -- Cian para cuidado personal
    WHEN LOWER(name) LIKE '%limpiar%' OR LOWER(name) LIKE '%cocinar%' OR LOWER(name) LIKE '%lavar%' THEN '#795548' -- Marrón para hogar
    WHEN LOWER(name) LIKE '%dinero%' OR LOWER(name) LIKE '%ahorrar%' OR LOWER(name) LIKE '%gasto%' THEN '#FF9800' -- Ámbar para finanzas
    WHEN LOWER(name) LIKE '%música%' OR LOWER(name) LIKE '%película%' OR LOWER(name) LIKE '%juego%' THEN '#F44336' -- Rojo para entretenimiento
    ELSE '#6366F1' -- Índigo por defecto
  END

WHERE icon_name = 'heart' OR icon_name IS NULL;

-- Verificar los cambios
SELECT 
  name,
  icon_name,
  icon_color,
  (SELECT name FROM categories WHERE id = habits.category_id) as category_name
FROM habits 
WHERE is_active = true
ORDER BY name;