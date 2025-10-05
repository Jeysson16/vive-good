-- Función para obtener hábitos sin eventos de calendario
CREATE OR REPLACE FUNCTION get_habits_without_calendar_events(p_user_id UUID)
RETURNS TABLE (
  user_habit_id UUID,
  user_id UUID,
  habit_id UUID,
  habit_name VARCHAR,
  habit_description TEXT,
  start_date DATE,
  end_date DATE,
  frequency VARCHAR,
  scheduled_time TIME,
  category_id UUID,
  icon_name VARCHAR,
  icon_color VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    uh.id as user_habit_id,
    uh.user_id,
    uh.habit_id,
    COALESCE(uh.custom_name, h.name) as habit_name,
    COALESCE(uh.custom_description, h.description) as habit_description,
    uh.start_date,
    uh.end_date,
    uh.frequency,
    uh.scheduled_time,
    h.category_id,
    h.icon_name,
    h.icon_color
  FROM user_habits uh
  INNER JOIN habits h ON uh.habit_id = h.id
  LEFT JOIN calendar_events ce ON uh.habit_id = ce.habit_id AND uh.user_id = ce.user_id
  WHERE uh.user_id = p_user_id
    AND uh.is_active = true
    AND ce.id IS NULL  -- No tiene eventos de calendario
  ORDER BY uh.created_at DESC;
END;
$$;

-- Función para limpiar eventos de calendario huérfanos
CREATE OR REPLACE FUNCTION cleanup_orphaned_calendar_events(p_user_id UUID)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  -- Eliminar eventos de calendario que no tienen hábito asociado activo
  DELETE FROM calendar_events ce
  WHERE ce.user_id = p_user_id
    AND ce.event_type = 'habit'
    AND ce.habit_id IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM user_habits uh 
      WHERE uh.habit_id = ce.habit_id 
        AND uh.user_id = ce.user_id 
        AND uh.is_active = true
    );
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  RETURN deleted_count;
END;
$$;

-- Función para verificar si un hábito necesita sincronización
CREATE OR REPLACE FUNCTION habit_needs_calendar_sync(p_user_id UUID, p_habit_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
  has_events BOOLEAN;
  is_active BOOLEAN;
BEGIN
  -- Verificar si el hábito está activo
  SELECT uh.is_active INTO is_active
  FROM user_habits uh
  WHERE uh.user_id = p_user_id AND uh.habit_id = p_habit_id;
  
  IF NOT FOUND OR NOT is_active THEN
    RETURN FALSE;
  END IF;
  
  -- Verificar si tiene eventos de calendario
  SELECT EXISTS(
    SELECT 1 FROM calendar_events ce
    WHERE ce.user_id = p_user_id AND ce.habit_id = p_habit_id
  ) INTO has_events;
  
  RETURN NOT has_events;
END;
$$;

-- Función para obtener estadísticas de sincronización
CREATE OR REPLACE FUNCTION get_sync_statistics(p_user_id UUID)
RETURNS TABLE (
  total_active_habits INTEGER,
  habits_with_events INTEGER,
  habits_without_events INTEGER,
  total_calendar_events INTEGER,
  orphaned_events INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    (SELECT COUNT(*)::INTEGER 
     FROM user_habits uh 
     WHERE uh.user_id = p_user_id AND uh.is_active = true) as total_active_habits,
    
    (SELECT COUNT(DISTINCT uh.habit_id)::INTEGER
     FROM user_habits uh
     INNER JOIN calendar_events ce ON uh.habit_id = ce.habit_id AND uh.user_id = ce.user_id
     WHERE uh.user_id = p_user_id AND uh.is_active = true) as habits_with_events,
    
    (SELECT COUNT(*)::INTEGER
     FROM user_habits uh
     LEFT JOIN calendar_events ce ON uh.habit_id = ce.habit_id AND uh.user_id = ce.user_id
     WHERE uh.user_id = p_user_id AND uh.is_active = true AND ce.id IS NULL) as habits_without_events,
    
    (SELECT COUNT(*)::INTEGER
     FROM calendar_events ce
     WHERE ce.user_id = p_user_id AND ce.event_type = 'habit') as total_calendar_events,
    
    (SELECT COUNT(*)::INTEGER
     FROM calendar_events ce
     WHERE ce.user_id = p_user_id 
       AND ce.event_type = 'habit'
       AND ce.habit_id IS NOT NULL
       AND NOT EXISTS (
         SELECT 1 FROM user_habits uh 
         WHERE uh.habit_id = ce.habit_id 
           AND uh.user_id = ce.user_id 
           AND uh.is_active = true
       )) as orphaned_events;
END;
$$;

-- Comentarios para documentar las funciones
COMMENT ON FUNCTION get_habits_without_calendar_events(UUID) IS 'Obtiene todos los hábitos activos de un usuario que no tienen eventos de calendario asociados';
COMMENT ON FUNCTION cleanup_orphaned_calendar_events(UUID) IS 'Elimina eventos de calendario que no tienen hábito asociado activo y retorna el número de eventos eliminados';
COMMENT ON FUNCTION habit_needs_calendar_sync(UUID, UUID) IS 'Verifica si un hábito específico necesita sincronización con eventos de calendario';
COMMENT ON FUNCTION get_sync_statistics(UUID) IS 'Obtiene estadísticas de sincronización entre hábitos y eventos de calendario para un usuario';