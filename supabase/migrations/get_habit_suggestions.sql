-- Stored procedure para obtener sugerencias de hábitos
-- Obtiene hábitos del total disponible sin relación con user_habits
CREATE OR REPLACE FUNCTION public.get_habit_suggestions_for_user(p_user_id uuid, p_limit integer DEFAULT 10)
 RETURNS TABLE(id uuid, name text, category_id uuid, is_suggested boolean)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        h.id,
        h.name,
        h.category_id,
        TRUE AS is_suggested
    FROM
        habits h
    LEFT JOIN
        user_habits uh ON h.id = uh.habit_id AND uh.user_id = p_user_id
    WHERE
        uh.habit_id IS NULL
    LIMIT p_limit;
END;
$function$;

-- Grant permissions to the new function
GRANT EXECUTE ON FUNCTION public.get_habit_suggestions_for_user(uuid, integer) TO anon;
GRANT EXECUTE ON FUNCTION public.get_habit_suggestions_for_user(uuid, integer) TO authenticated;