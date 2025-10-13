-- CORRECCIÓN CRÍTICA: Restaurar funcionalidad de stored procedures
-- Problema: INNER JOIN excluye hábitos personalizados causando loading infinito
-- Solución: Usar LEFT JOIN y COALESCE para incluir todos los hábitos

-- 1. Corregir get_dashboard_habits
DROP FUNCTION IF EXISTS get_dashboard_habits(UUID, DATE);

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
    COALESCE(h.id, uh.id) as habit_id,
    COALESCE(h.name, uh.custom_name, 'Hábito personalizado') as habit_name,
    COALESCE(h.description, uh.custom_description, '') as habit_description,
    COALESCE(h.icon_name, 'star') as habit_icon_name,
    COALESCE(h.icon_color, '#6366F1') as habit_icon_color,
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
  LEFT JOIN habits h ON uh.habit_id = h.id  -- CAMBIO CRÍTICO: LEFT JOIN en lugar de INNER JOIN
  LEFT JOIN categories c ON COALESCE(h.category_id, uh.category_id) = c.id
  
  -- LEFT JOIN con calendar_events para incluir hábitos sin eventos
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
  ) ce ON ce.habit_id = COALESCE(h.id, uh.id)  -- CAMBIO: usar COALESCE para hábitos personalizados
  
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

-- 2. Corregir get_user_habits_with_details
DROP FUNCTION IF EXISTS get_user_habits_with_details(UUID, UUID);

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
    COALESCE(h.id, uh.id) as habit_id,
    COALESCE(h.name, uh.custom_name, 'Hábito personalizado') as habit_name,
    COALESCE(h.description, uh.custom_description, '') as habit_description,
    COALESCE(h.icon_name, 'star') as habit_icon_name,
    COALESCE(h.icon_color, '#6366F1') as habit_icon_color,
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
  LEFT JOIN habits h ON uh.habit_id = h.id  -- CAMBIO CRÍTICO: LEFT JOIN en lugar de INNER JOIN
  LEFT JOIN categories c ON COALESCE(h.category_id, uh.category_id) = c.id
  
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
    AND (p_category_id IS NULL OR COALESCE(h.category_id, uh.category_id) = p_category_id)
    -- Mostrar TODOS los hábitos del usuario (pendientes, aplazados, cumplidos)
    -- Sin filtrar por is_active ni fechas para la pantalla de hábitos
  
  ORDER BY 
    uh.scheduled_time ASC NULLS LAST,
    COALESCE(h.name, uh.custom_name) ASC;
END;
$$;

-- Grant permissions para ambas funciones
GRANT EXECUTE ON FUNCTION get_dashboard_habits(UUID, DATE) TO anon;
GRANT EXECUTE ON FUNCTION get_dashboard_habits(UUID, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_habits_with_details(UUID, UUID) TO anon;
GRANT EXECUTE ON FUNCTION get_user_habits_with_details(UUID, UUID) TO authenticated;

-- Comments
COMMENT ON FUNCTION get_dashboard_habits(UUID, DATE) IS 'CORREGIDO: Obtiene todos los hábitos del usuario para el dashboard incluyendo hábitos personalizados con LEFT JOIN y COALESCE';
COMMENT ON FUNCTION get_user_habits_with_details(UUID, UUID) IS 'CORREGIDO: Obtiene TODOS los user_habits del usuario incluyendo hábitos personalizados con LEFT JOIN y COALESCE';