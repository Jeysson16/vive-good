-- Create stored procedure for habit suggestions
-- This returns all available habits without user relationship
CREATE OR REPLACE FUNCTION get_habit_suggestions()
RETURNS TABLE (
  id UUID,
  name TEXT,
  description TEXT,
  category_id UUID,
  icon_name TEXT,
  icon_color TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    h.id,
    h.name,
    h.description,
    h.category_id,
    h.icon_name,
    h.icon_color,
    h.created_at,
    h.updated_at
  FROM habits h
  WHERE h.is_active = true
  ORDER BY h.name ASC;
END;
$$;

-- Create stored procedure for dashboard habits
-- This returns user habits optimized for dashboard display
CREATE OR REPLACE FUNCTION get_dashboard_habits(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 10,
  p_include_completion BOOLEAN DEFAULT true
)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  habit_id UUID,
  target_frequency INTEGER,
  frequency_type TEXT,
  is_active BOOLEAN,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  habit_name TEXT,
  habit_description TEXT,
  habit_icon_name TEXT,
  habit_icon_color TEXT,
  category_name TEXT,
  today_completed BOOLEAN,
  completion_count INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    uh.id,
    uh.user_id,
    uh.habit_id,
    uh.target_frequency,
    uh.frequency_type,
    uh.is_active,
    uh.created_at,
    uh.updated_at,
    h.name as habit_name,
    h.description as habit_description,
    h.icon_name as habit_icon_name,
    h.icon_color as habit_icon_color,
    c.name as category_name,
    CASE 
      WHEN p_include_completion THEN
        EXISTS(
          SELECT 1 FROM habit_logs hl 
          WHERE hl.user_habit_id = uh.id 
          AND DATE(hl.completed_at) = CURRENT_DATE
        )
      ELSE false
    END as today_completed,
    CASE 
      WHEN p_include_completion THEN
        COALESCE((
          SELECT COUNT(*) FROM habit_logs hl 
          WHERE hl.user_habit_id = uh.id 
          AND DATE(hl.completed_at) = CURRENT_DATE
        ), 0)::INTEGER
      ELSE 0
    END as completion_count
  FROM user_habits uh
  INNER JOIN habits h ON uh.habit_id = h.id
  INNER JOIN categories c ON h.category_id = c.id
  WHERE uh.user_id = p_user_id
    AND uh.is_active = true
    AND h.is_active = true
  ORDER BY uh.created_at DESC
  LIMIT p_limit;
END;
$$;

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION get_habit_suggestions() TO authenticated;
GRANT EXECUTE ON FUNCTION get_dashboard_habits(UUID, INTEGER, BOOLEAN) TO authenticated;

-- Grant execute permissions to anon users for suggestions
GRANT EXECUTE ON FUNCTION get_habit_suggestions() TO anon;