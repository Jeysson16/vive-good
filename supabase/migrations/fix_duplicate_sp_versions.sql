-- Eliminar todas las versiones del stored procedure get_dashboard_habits
-- para evitar conflictos y duplicación

-- Eliminar versión antigua con 3 parámetros (UUID, INTEGER, BOOLEAN)
DROP FUNCTION IF EXISTS get_dashboard_habits(UUID, INTEGER, BOOLEAN);

-- Eliminar cualquier otra versión que pueda existir
DROP FUNCTION IF EXISTS get_dashboard_habits(UUID, DATE, UUID);
DROP FUNCTION IF EXISTS get_dashboard_habits(UUID, DATE);

-- Recrear la versión correcta del stored procedure
CREATE OR REPLACE FUNCTION get_dashboard_habits(
  p_user_id UUID,
  p_date DATE DEFAULT CURRENT_DATE
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
  is_completed_today BOOLEAN,
  completion_count_today INTEGER,
  last_completed_at TIMESTAMPTZ,
  streak_count INTEGER,
  total_completions BIGINT,
  calendar_event_id UUID,
  event_start_time TIME,
  event_end_time TIME
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    uh.id as user_habit_id,
    COALESCE(h.id, uh.category_id) as habit_id, -- Use category_id for custom habits
    COALESCE(h.name, uh.custom_name) as habit_name,
    COALESCE(h.description, uh.custom_description) as habit_description,
    COALESCE(h.icon_name, c.icon) as habit_icon_name,
    COALESCE(h.icon_color, c.color) as habit_icon_color,
    COALESCE(h.category_id, uh.category_id) as category_id,
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
    COALESCE(total_stats.total_completions, 0) as total_completions,
    
    -- Calendar event information
    ce.id as calendar_event_id,
    ce.start_time as event_start_time,
    ce.end_time as event_end_time
    
  FROM user_habits uh
  LEFT JOIN habits h ON uh.habit_id = h.id
  LEFT JOIN categories c ON COALESCE(h.category_id, uh.category_id) = c.id
  
  -- Left join with calendar_events and use DISTINCT ON to avoid duplicates
  LEFT JOIN (
    SELECT DISTINCT ON (ce.habit_id) 
      ce.id,
      ce.habit_id,
      ce.start_time,
      ce.end_time
    FROM calendar_events ce
    WHERE ce.user_id = p_user_id 
      AND (
        -- Direct date match
        ce.start_date = p_date
        OR (
          -- Recurring events
          ce.recurrence_type IS NOT NULL 
          AND ce.recurrence_type != 'none'
          AND ce.start_date <= p_date
          AND (ce.recurrence_end_date IS NULL OR ce.recurrence_end_date >= p_date)
          AND (
            -- Daily recurrence
            (ce.recurrence_type = 'daily' AND (p_date - ce.start_date) % COALESCE(ce.recurrence_interval, 1) = 0)
            OR
            -- Weekly recurrence
            (ce.recurrence_type = 'weekly' AND EXTRACT(DOW FROM p_date)::INTEGER = ANY(ce.recurrence_days))
            OR
            -- Monthly recurrence
            (ce.recurrence_type = 'monthly' AND EXTRACT(DAY FROM p_date) = EXTRACT(DAY FROM ce.start_date))
          )
        )
      )
      AND ce.is_completed = false  -- Only show pending events
    ORDER BY ce.habit_id, ce.start_time ASC NULLS LAST
  ) ce ON ce.habit_id = COALESCE(h.id, uh.category_id)
  
  -- Today's completion logs
  LEFT JOIN (
    SELECT 
      uhl.user_habit_id,
      COUNT(*) as completion_count
    FROM user_habit_logs uhl
    WHERE DATE(uhl.completed_at) = p_date
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
      AND DATE(uhl.completed_at) >= (p_date - INTERVAL '30 days')
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
    AND (
      uh.end_date IS NULL 
      OR uh.end_date >= p_date
    )
    AND uh.start_date <= p_date
  
  ORDER BY 
    c.name ASC NULLS LAST,  -- Order by category name first
    ce.start_time ASC NULLS LAST,
    uh.scheduled_time ASC NULLS LAST,
    COALESCE(h.name, uh.custom_name) ASC;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_dashboard_habits(UUID, DATE) TO anon;
GRANT EXECUTE ON FUNCTION get_dashboard_habits(UUID, DATE) TO authenticated;

-- Comment
COMMENT ON FUNCTION get_dashboard_habits(UUID, DATE) IS 'Obtiene todos los hábitos del usuario para el dashboard con información completa de progreso y estadísticas, soportando tanto hábitos predefinidos como personalizados';

-- Verificar que no hay duplicados
SELECT 
    COALESCE(h.name, uh.custom_name) as habit_name,
    COUNT(*) as count
FROM user_habits uh
LEFT JOIN habits h ON uh.habit_id = h.id
WHERE uh.user_id = '8e622f30-084d-4015-a3b8-6ae33e8ee991'
  AND uh.is_active = true
GROUP BY COALESCE(h.name, uh.custom_name)
HAVING COUNT(*) > 1;