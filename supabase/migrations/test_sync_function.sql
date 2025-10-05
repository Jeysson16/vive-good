-- Probar la función de sincronización
-- Primero obtener un usuario con hábitos
SELECT 
    u.id as user_id,
    u.email,
    COUNT(uh.id) as total_habits
FROM auth.users u
LEFT JOIN user_habits uh ON u.id = uh.user_id AND uh.is_active = true
GROUP BY u.id, u.email
HAVING COUNT(uh.id) > 0
ORDER BY total_habits DESC
LIMIT 1;

-- Verificar hábitos sin eventos para el primer usuario
-- Nota: Reemplazar el UUID con el resultado de la consulta anterior
SELECT * FROM get_habits_without_calendar_events(
    (SELECT u.id FROM auth.users u
     LEFT JOIN user_habits uh ON u.id = uh.user_id AND uh.is_active = true
     GROUP BY u.id
     HAVING COUNT(uh.id) > 0
     ORDER BY COUNT(uh.id) DESC
     LIMIT 1)
);