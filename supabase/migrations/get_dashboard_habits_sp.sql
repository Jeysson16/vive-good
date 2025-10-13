-- Stored procedure para obtener hábitos del dashboard/inicio
-- Optimiza la consulta de hábitos del usuario con información completa
CREATE OR REPLACE FUNCTION get_dashboard_habits(
  p_user_id UUID,
  p_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  user_habit_id UUID,
  habit_id UUID,
  habit_name TEXT,
  habit_description TEXT,
  habit_icon TEXT,
  habit_color TEXT,
  category_id UUID,
  category_name TEXT,
  target_frequency INTEGER,
  current_streak INTEGER,
  is_completed_today BOOLEAN,
  completion_time TIMESTAMP WITH TIME ZONE,
  difficulty_level INTEGER,
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
    h.icon as habit_icon,
    h.color as habit_color,
    h.category_id,
    c.name as category_name,
    uh.target_frequency,
    uh.current_streak,
    CASE 
      WHEN hl.id IS NOT NULL THEN true 
      ELSE false 
    END as is_completed_today,
    hl.completed_at as completion_time,
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
    h.difficulty_level ASC,
    uh.created_at ASC;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_dashboard_habits(UUID, DATE) TO anon;
GRANT EXECUTE ON FUNCTION get_dashboard_habits(UUID, DATE) TO authenticated;