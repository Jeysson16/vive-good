-- Stored Procedure para obtener user_habits con detalles de habits
-- Optimizado para la vista "Mis Hábitos" con INNER JOIN

CREATE OR REPLACE FUNCTION get_user_habits_with_details(
  p_user_id UUID,
  p_category_id UUID DEFAULT NULL
)
RETURNS TABLE (
  user_habit_id UUID,
  habit_id UUID,
  habit_name VARCHAR,
  habit_description TEXT,
  habit_icon_name VARCHAR,
  habit_icon_color VARCHAR,
  category_id UUID,
  category_name VARCHAR,
  category_color VARCHAR,
  category_icon VARCHAR,
  frequency VARCHAR,
  frequency_details JSONB,
  scheduled_time TIME,
  notification_time TIME,
  notifications_enabled BOOLEAN,
  start_date DATE,
  end_date DATE,
  is_active BOOLEAN,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  is_completed_today BOOLEAN,
  completion_count_today INTEGER,
  last_completed_at TIMESTAMPTZ,
  streak_count INTEGER,
  total_completions BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    uh.id as user_habit_id,
    h.id as habit_id,
    h.name as habit_name,
    h.description as habit_description,
    'heart'::VARCHAR as habit_icon_name,
    '#4CAF50'::VARCHAR as habit_icon_color,
    c.id as category_id,
    c.name as category_name,
    c.color as category_color,
    c.icon as category_icon,
    uh.frequency,
    uh.frequency_details,
    uh.scheduled_time,
    uh.notification_time,
    uh.notifications_enabled,
    uh.start_date,
    uh.end_date,
    uh.is_active,
    uh.created_at,
    uh.updated_at,
    
    -- Check if completed today
    CASE 
      WHEN today_logs.completion_count > 0 THEN true 
      ELSE false 
    END as is_completed_today,
    
    COALESCE(today_logs.completion_count, 0)::INTEGER as completion_count_today,
    
    -- Last completion timestamp
    recent_logs.last_completed_at,
    
    -- Calculate streak (simplified version)
    COALESCE(streak_data.streak_count, 0)::INTEGER as streak_count,
    
    -- Total completions
    COALESCE(total_stats.total_completions, 0) as total_completions
    
  FROM user_habits uh
  INNER JOIN habits h ON uh.habit_id = h.id
  LEFT JOIN categories c ON h.category_id = c.id
  
  -- Today's completion logs
  LEFT JOIN (
    SELECT 
      uhl.user_habit_id,
      COUNT(*) as completion_count
    FROM user_habit_logs uhl
    WHERE DATE(uhl.completed_at) = CURRENT_DATE
      AND uhl.status = 'completed'
    GROUP BY uhl.user_habit_id
  ) today_logs ON uh.id = today_logs.user_habit_id
  
  -- Most recent completion
  LEFT JOIN (
    SELECT DISTINCT ON (uhl.user_habit_id)
      uhl.user_habit_id,
      uhl.completed_at as last_completed_at
    FROM user_habit_logs uhl
    WHERE uhl.status = 'completed'
    ORDER BY uhl.user_habit_id, uhl.completed_at DESC
  ) recent_logs ON uh.id = recent_logs.user_habit_id
  
  -- Streak calculation (simplified - consecutive days)
  LEFT JOIN (
    SELECT 
      uhl.user_habit_id,
      COUNT(DISTINCT DATE(uhl.completed_at)) as streak_count
    FROM user_habit_logs uhl
    WHERE uhl.status = 'completed'
      AND DATE(uhl.completed_at) >= (CURRENT_DATE - INTERVAL '30 days')
    GROUP BY uhl.user_habit_id
  ) streak_data ON uh.id = streak_data.user_habit_id
  
  -- Total completion stats
  LEFT JOIN (
    SELECT 
      uhl.user_habit_id,
      COUNT(*) as total_completions
    FROM user_habit_logs uhl
    WHERE uhl.status = 'completed'
    GROUP BY uhl.user_habit_id
  ) total_stats ON uh.id = total_stats.user_habit_id
  
  WHERE 
    uh.user_id = p_user_id
    AND uh.is_active = true
    AND (p_category_id IS NULL OR h.category_id = p_category_id)
    AND (
      uh.end_date IS NULL 
      OR uh.end_date >= CURRENT_DATE
    )
    AND uh.start_date <= CURRENT_DATE
  
  ORDER BY 
    uh.scheduled_time ASC NULLS LAST,
    h.name ASC;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_user_habits_with_details(UUID, UUID) TO anon;
GRANT EXECUTE ON FUNCTION get_user_habits_with_details(UUID, UUID) TO authenticated;

-- Comment
COMMENT ON FUNCTION get_user_habits_with_details(UUID, UUID) IS 'Obtiene user_habits del usuario con detalles completos de habits usando INNER JOIN';