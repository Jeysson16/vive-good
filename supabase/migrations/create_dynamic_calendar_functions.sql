-- Función para obtener hábitos activos para el calendario dinámico
CREATE OR REPLACE FUNCTION get_active_user_habits_for_calendar(p_user_id UUID)
RETURNS TABLE (
  user_habit_id UUID,
  habit_id UUID,
  habit_name VARCHAR,
  habit_description TEXT,
  habit_icon_name VARCHAR,
  habit_category VARCHAR,
  scheduled_time TIME,
  frequency VARCHAR,
  start_date DATE,
  end_date DATE,
  custom_name VARCHAR,
  custom_description TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    uh.id as user_habit_id,
    uh.habit_id,
    COALESCE(uh.custom_name, h.name) as habit_name,
    COALESCE(uh.custom_description, h.description) as habit_description,
    h.icon_name as habit_icon_name,
    COALESCE(c.name, 'Sin categoría') as habit_category,
    uh.scheduled_time,
    uh.frequency,
    uh.start_date,
    uh.end_date,
    uh.custom_name,
    uh.custom_description
  FROM user_habits uh
  INNER JOIN habits h ON uh.habit_id = h.id
  LEFT JOIN categories c ON h.category_id = c.id
  WHERE uh.user_id = p_user_id 
    AND uh.is_active = true
    AND uh.scheduled_time IS NOT NULL
    AND (uh.end_date IS NULL OR uh.end_date >= CURRENT_DATE)
  ORDER BY uh.scheduled_time ASC;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener eventos completados de hábitos
CREATE OR REPLACE FUNCTION get_habit_completion_events(
  p_user_id UUID,
  p_start_date DATE DEFAULT NULL,
  p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
  event_id UUID,
  user_habit_id UUID,
  habit_id UUID,
  completed_at TIMESTAMPTZ,
  event_date DATE,
  notes TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ce.id as event_id,
    uh.id as user_habit_id,
    ce.habit_id,
    ce.completed_at,
    ce.start_date::DATE as event_date,
    ce.description as notes
  FROM calendar_events ce
  INNER JOIN user_habits uh ON ce.habit_id = uh.habit_id AND ce.user_id = uh.user_id
  WHERE ce.user_id = p_user_id 
    AND ce.habit_id IS NOT NULL
    AND ce.completed_at IS NOT NULL
    AND (p_start_date IS NULL OR ce.start_date::DATE >= p_start_date)
    AND (p_end_date IS NULL OR ce.start_date::DATE <= p_end_date)
  ORDER BY ce.start_date ASC;
END;
$$ LANGUAGE plpgsql;

-- Función para obtener eventos manuales (no relacionados con hábitos)
CREATE OR REPLACE FUNCTION get_manual_calendar_events(
  p_user_id UUID,
  p_start_date DATE DEFAULT NULL,
  p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
  event_id UUID,
  title VARCHAR,
  description TEXT,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  start_time TIME,
  end_time TIME,
  event_type VARCHAR,
  is_all_day BOOLEAN,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ce.id as event_id,
    ce.title,
    ce.description,
    ce.start_date,
    ce.end_date,
    ce.start_time,
    ce.end_time,
    ce.event_type,
    ce.is_all_day,
    ce.completed_at,
    ce.created_at
  FROM calendar_events ce
  WHERE ce.user_id = p_user_id 
    AND ce.habit_id IS NULL  -- Solo eventos manuales
    AND (p_start_date IS NULL OR ce.start_date::DATE >= p_start_date)
    AND (p_end_date IS NULL OR ce.start_date::DATE <= p_end_date)
  ORDER BY ce.start_date ASC;
END;
$$ LANGUAGE plpgsql;

-- Comentarios sobre las funciones
COMMENT ON FUNCTION get_active_user_habits_for_calendar(UUID) IS 'Obtiene todos los hábitos activos de un usuario para generar eventos de calendario dinámicamente';
COMMENT ON FUNCTION get_habit_completion_events(UUID, DATE, DATE) IS 'Obtiene los eventos de completado de hábitos para un rango de fechas';
COMMENT ON FUNCTION get_manual_calendar_events(UUID, DATE, DATE) IS 'Obtiene eventos manuales (no relacionados con hábitos) para un rango de fechas';