-- Script para limpiar datos duplicados en user_habits
-- Este script elimina registros duplicados manteniendo solo el más reciente

-- Función para limpiar duplicados en user_habits
CREATE OR REPLACE FUNCTION clean_duplicate_user_habits()
RETURNS TABLE(
    cleaned_count INTEGER,
    details TEXT
) 
LANGUAGE plpgsql
AS $$
DECLARE
    duplicate_count INTEGER := 0;
    cleanup_details TEXT := '';
BEGIN
    -- Crear tabla temporal con los IDs a mantener (los más recientes por usuario/hábito)
    CREATE TEMP TABLE IF NOT EXISTS habits_to_keep AS
    SELECT DISTINCT ON (user_id, habit_id) 
        id,
        user_id,
        habit_id,
        is_active,
        created_at
    FROM user_habits
    ORDER BY user_id, habit_id, created_at DESC;

    -- Contar cuántos duplicados hay antes de la limpieza
    SELECT COUNT(*) INTO duplicate_count
    FROM user_habits uh
    WHERE uh.id NOT IN (SELECT id FROM habits_to_keep);

    -- Eliminar los duplicados (mantener solo los más recientes)
    DELETE FROM user_habits 
    WHERE id NOT IN (SELECT id FROM habits_to_keep);

    -- Preparar detalles de la limpieza
    cleanup_details := format(
        'Eliminados %s registros duplicados. Mantenidos los registros más recientes por usuario/hábito.',
        duplicate_count
    );

    -- Limpiar tabla temporal
    DROP TABLE IF EXISTS habits_to_keep;

    -- Retornar resultados
    RETURN QUERY SELECT duplicate_count, cleanup_details;
END;
$$;

-- Función para verificar duplicados antes de limpiar
CREATE OR REPLACE FUNCTION check_duplicate_user_habits()
RETURNS TABLE(
    user_id UUID,
    habit_id UUID,
    habit_name TEXT,
    duplicate_count BIGINT,
    active_count BIGINT,
    inactive_count BIGINT,
    record_ids TEXT
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        uh.user_id,
        uh.habit_id,
        h.name as habit_name,
        COUNT(*) as duplicate_count,
        COUNT(CASE WHEN uh.is_active = true THEN 1 END) as active_count,
        COUNT(CASE WHEN uh.is_active = false THEN 1 END) as inactive_count,
        STRING_AGG(uh.id::text, ', ' ORDER BY uh.created_at DESC) as record_ids
    FROM user_habits uh
    JOIN habits h ON h.id = uh.habit_id
    GROUP BY uh.user_id, uh.habit_id, h.name
    HAVING COUNT(*) > 1
    ORDER BY duplicate_count DESC;
END;
$$;

-- Función para verificar la integridad después de la limpieza
CREATE OR REPLACE FUNCTION verify_user_habits_integrity()
RETURNS TABLE(
    check_name TEXT,
    status TEXT,
    details TEXT
) 
LANGUAGE plpgsql
AS $$
DECLARE
    duplicate_count INTEGER;
    orphan_count INTEGER;
    total_count INTEGER;
BEGIN
    -- Verificar que no hay duplicados
    SELECT COUNT(*) INTO duplicate_count
    FROM (
        SELECT user_id, habit_id, COUNT(*) 
        FROM user_habits 
        GROUP BY user_id, habit_id 
        HAVING COUNT(*) > 1
    ) duplicates;

    RETURN QUERY SELECT 
        'Duplicados eliminados'::TEXT,
        CASE WHEN duplicate_count = 0 THEN 'PASS' ELSE 'FAIL' END::TEXT,
        format('Duplicados restantes: %s', duplicate_count)::TEXT;

    -- Verificar que no hay registros huérfanos (hábitos que no existen)
    SELECT COUNT(*) INTO orphan_count
    FROM user_habits uh
    LEFT JOIN habits h ON uh.habit_id = h.id
    WHERE h.id IS NULL;

    RETURN QUERY SELECT 
        'Referencias válidas'::TEXT,
        CASE WHEN orphan_count = 0 THEN 'PASS' ELSE 'WARNING' END::TEXT,
        format('Registros huérfanos: %s', orphan_count)::TEXT;

    -- Estadísticas generales
    SELECT COUNT(*) INTO total_count FROM user_habits;

    RETURN QUERY SELECT 
        'Total registros'::TEXT,
        'INFO'::TEXT,
        format('Total user_habits: %s', total_count)::TEXT;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION clean_duplicate_user_habits() TO authenticated;
GRANT EXECUTE ON FUNCTION check_duplicate_user_habits() TO authenticated;
GRANT EXECUTE ON FUNCTION verify_user_habits_integrity() TO authenticated;

-- Comentarios
COMMENT ON FUNCTION clean_duplicate_user_habits() IS 'Limpia registros duplicados en user_habits manteniendo el más reciente';
COMMENT ON FUNCTION check_duplicate_user_habits() IS 'Verifica la existencia de duplicados en user_habits antes de limpiar';
COMMENT ON FUNCTION verify_user_habits_integrity() IS 'Verifica la integridad de los datos después de la limpieza';

-- Instrucciones de uso:
-- 1. Verificar duplicados: SELECT * FROM check_duplicate_user_habits();
-- 2. Limpiar duplicados: SELECT * FROM clean_duplicate_user_habits();
-- 3. Verificar integridad: SELECT * FROM verify_user_habits_integrity()