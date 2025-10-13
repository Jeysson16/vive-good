-- Stored procedure para obtener hábitos del dashboard/inicio
-- Optimiza la consulta de hábitos del usuario con información completa

-- Primero eliminamos la función existente para cambiar los tipos de retorno
DROP FUNCTION IF EXISTS get_dashboard_habits(UUID, DATE);

CREATE OR REPLACE FUNCTION get_dashboard_habits(
  p_user_id UUID,
  p_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  user_habit_id UUID,
  habit_id UUID,
  habit_name VARCHAR(200),
  habit_description TEXT,
  habit_icon_name VARCHAR(50),
  habit_icon_color VARCHAR(7),
  category_id UUID,
  category_name VARCHAR(100),
  frequency VARCHAR(20),
  frequency_details JSONB,
  scheduled_time TIME,
  notification_time TIME,
  notifications_enabled BOOLEAN,
  start_date DATE,
  end_date DATE,
  is_active BOOLEAN,
  is_completed_today BOOLEAN,
  completion_time TIMESTAMP WITH TIME ZONE,
  completion_count_today INTEGER,
  last_completed_at TIMESTAMP WITH TIME ZONE,
  streak_count INTEGER,
  total_completions INTEGER,
  difficulty_level VARCHAR(20),
  estimated_duration INTEGER,
  priority_order INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    uh.id as user_habit_id,
    h.id as habit_id,
    h.name as habit_name,
    h.description as habit_description,
    c.icon as habit_icon_name,
    c.color as habit_icon_color,
    h.category_id,
    c.name as category_name,
    uh.frequency,
    uh.frequency_details,
    uh.scheduled_time,
    uh.notification_time,
    COALESCE(uh.notifications_enabled, false) as notifications_enabled,
    uh.start_date,
    uh.end_date,
    COALESCE(uh.is_active, true) as is_active,
    CASE 
      WHEN hl.id IS NOT NULL THEN true 
      ELSE false 
    END as is_completed_today,
    hl.completed_at as completion_time,
    CASE 
      WHEN hl.id IS NOT NULL THEN 1 
      ELSE 0 
    END as completion_count_today,
    hl.completed_at as last_completed_at,
    0 as streak_count,  -- Por ahora 0, se puede calcular después
    0 as total_completions,  -- Por ahora 0, se puede calcular después
    h.difficulty_level,
    h.estimated_duration,
    CASE 
      WHEN hl.id IS NULL THEN 1  -- Hábitos no completados tienen prioridad
      ELSE 2  -- Hábitos completados tienen menor prioridad
    END as priority_order
  FROM user_habits uh
  INNER JOIN habits h ON uh.habit_id = h.id
  INNER JOIN categories c ON h.category_id = c.id
  LEFT JOIN user_habit_logs hl ON (
    hl.user_habit_id = uh.id 
    AND DATE(hl.completed_at) = p_date
    AND hl.status = 'completed'
  )
  WHERE uh.user_id = p_user_id
    AND uh.is_active = true
    AND h.is_active = true
  ORDER BY 
    priority_order ASC,
    CASE h.difficulty_level 
      WHEN 'easy' THEN 1
      WHEN 'medium' THEN 2  
      WHEN 'hard' THEN 3
      ELSE 4
    END ASC,
    uh.created_at ASC;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_dashboard_habits(UUID, DATE) TO anon;
GRANT EXECUTE ON FUNCTION get_dashboard_habits(UUID, DATE) TO authenticated;