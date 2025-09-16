-- Stored Procedure para obtener sugerencias de hábitos
-- Devuelve hábitos de la biblioteca que NO están enlazados al usuario actual

CREATE OR REPLACE FUNCTION get_habit_suggestions_not_linked(
  p_user_id UUID,
  p_category_id UUID DEFAULT NULL,
  p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  id UUID,
  name VARCHAR,
  description TEXT,
  icon_name VARCHAR,
  icon_color VARCHAR,
  category_id UUID,
  category_name VARCHAR,
  category_color VARCHAR,
  category_icon VARCHAR,
  difficulty_level VARCHAR,
  estimated_duration INTEGER,
  benefits TEXT[],
  tips TEXT[],
  is_active BOOLEAN,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  popularity_score INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    h.id,
    h.name,
    h.description,
    h.icon_name,
    h.icon_color,
    c.id as category_id,
    c.name as category_name,
    c.color as category_color,
    c.icon as category_icon,
    h.difficulty_level,
    h.estimated_duration,
    h.benefits,
    h.tips,
    h.is_active,
    h.created_at,
    h.updated_at,
    
    -- Calculate popularity score based on how many users have this habit
    COALESCE(popularity_stats.user_count, 0)::INTEGER as popularity_score
    
  FROM habits h
  LEFT JOIN categories c ON h.category_id = c.id
  
  -- Calculate popularity (how many users have this habit)
  LEFT JOIN (
    SELECT 
      uh.habit_id,
      COUNT(DISTINCT uh.user_id) as user_count
    FROM user_habits uh
    WHERE uh.is_active = true
    GROUP BY uh.habit_id
  ) popularity_stats ON h.id = popularity_stats.habit_id
  
  WHERE 
    h.is_active = true
    AND (p_category_id IS NULL OR h.category_id = p_category_id)
    
    -- CRITICAL: Exclude habits that the user already has
    AND h.id NOT IN (
      SELECT uh.habit_id 
      FROM user_habits uh 
      WHERE uh.user_id = p_user_id 
        AND uh.is_active = true
    )
  
  ORDER BY 
    -- Prioritize by popularity and then by name
    popularity_stats.user_count DESC NULLS LAST,
    h.name ASC
  
  LIMIT p_limit;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_habit_suggestions_not_linked(UUID, UUID, INTEGER) TO anon;
GRANT EXECUTE ON FUNCTION get_habit_suggestions_not_linked(UUID, UUID, INTEGER) TO authenticated;

-- Comment
COMMENT ON FUNCTION get_habit_suggestions_not_linked(UUID, UUID, INTEGER) IS 'Obtiene sugerencias de hábitos de la biblioteca que NO están enlazados al usuario actual';