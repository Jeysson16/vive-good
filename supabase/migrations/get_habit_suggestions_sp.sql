-- Stored Procedure para obtener sugerencias de hábitos
-- Sin relación con user_habits, basado en todos los hábitos disponibles

CREATE OR REPLACE FUNCTION get_popular_habit_suggestions(
  p_user_id UUID DEFAULT NULL,
  p_category_id UUID DEFAULT NULL,
  p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  id UUID,
  name VARCHAR,
  description TEXT,
  category_id UUID,
  category_name VARCHAR,
  category_color VARCHAR,
  category_icon VARCHAR,
  is_popular BOOLEAN,
  usage_count BIGINT
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
    h.category_id,
    c.name as category_name,
    c.color as category_color,
    c.icon as category_icon,
    CASE 
      WHEN usage_stats.usage_count > 5 THEN true 
      ELSE false 
    END as is_popular,
    COALESCE(usage_stats.usage_count, 0) as usage_count
  FROM habits h
  LEFT JOIN categories c ON h.category_id = c.id
  LEFT JOIN (
    SELECT 
      uh.habit_id,
      COUNT(*) as usage_count
    FROM user_habits uh
    WHERE uh.is_active = true
    GROUP BY uh.habit_id
  ) usage_stats ON h.id = usage_stats.habit_id
  WHERE 
    (p_category_id IS NULL OR h.category_id = p_category_id)
    AND (
      p_user_id IS NULL 
      OR h.id NOT IN (
        SELECT uh.habit_id 
        FROM user_habits uh 
        WHERE uh.user_id = p_user_id 
        AND uh.is_active = true
      )
    )
  ORDER BY 
    usage_stats.usage_count DESC NULLS LAST,
    h.created_at DESC
  LIMIT p_limit;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_popular_habit_suggestions(UUID, UUID, INTEGER) TO anon;
GRANT EXECUTE ON FUNCTION get_popular_habit_suggestions(UUID, UUID, INTEGER) TO authenticated;

-- Comment
COMMENT ON FUNCTION get_popular_habit_suggestions(UUID, UUID, INTEGER) IS 'Obtiene sugerencias de hábitos basadas en popularidad y sin relación con user_habits del usuario';