-- Probar el stored procedure corregido
SELECT * FROM get_dashboard_habits( 
   p_user_id := '8e622f30-084d-4015-a3b8-6ae33e8ee991'::uuid, 
   p_date := CURRENT_DATE 
);

-- También verificar si hay datos en user_habits para este usuario
SELECT 
    'USER_HABITS' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_records
FROM user_habits 
WHERE user_id = '8e622f30-084d-4015-a3b8-6ae33e8ee991'::uuid

UNION ALL

SELECT 
    'HABITS' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_records
FROM habits

UNION ALL

SELECT 
    'CATEGORIES' as table_name,
    COUNT(*) as total_records,
    COUNT(*) as active_records
FROM categories;

-- Verificar datos específicos del usuario
SELECT 
    uh.id,
    uh.custom_name,
    h.name as habit_name,
    uh.start_date,
    uh.end_date,
    uh.is_active,
    uh.frequency,
    CURRENT_DATE as today,
    CASE 
        WHEN uh.end_date IS NULL OR uh.end_date >= CURRENT_DATE THEN 'VALID_DATE_RANGE'
        ELSE 'EXPIRED'
    END as date_status,
    CASE 
        WHEN uh.start_date <= CURRENT_DATE THEN 'STARTED'
        ELSE 'NOT_STARTED'
    END as start_status
FROM user_habits uh
LEFT JOIN habits h ON uh.habit_id = h.id
WHERE uh.user_id = '8e622f30-084d-4015-a3b8-6ae33e8ee991'::uuid
ORDER BY uh.created_at DESC;