-- Script de prueba detallado para verificar las sugerencias de hábitos
-- Este script prueba diferentes escenarios para identificar el problema

-- Función de prueba para verificar las sugerencias con un usuario específico
CREATE OR REPLACE FUNCTION test_habit_suggestions_detailed(test_user_id UUID)
RETURNS TABLE(
    test_step TEXT,
    status TEXT,
    details TEXT,
    count_value INTEGER
) 
LANGUAGE plpgsql
AS $$
DECLARE
    user_habits_count INTEGER;
    suggested_habits_count INTEGER;
    overlapping_habits_count INTEGER;
    total_habits_count INTEGER;
BEGIN
    -- Test 1: Verificar que el usuario existe y tiene hábitos
    SELECT COUNT(*) INTO user_habits_count
    FROM user_habits uh
    WHERE uh.user_id = test_user_id AND uh.is_active = true;

    RETURN QUERY SELECT 
        'Test 1: Usuario tiene hábitos activos'::TEXT,
        CASE WHEN user_habits_count > 0 THEN 'PASS' ELSE 'FAIL' END::TEXT,
        format('Usuario %s tiene %s hábitos activos', test_user_id, user_habits_count)::TEXT,
        user_habits_count;

    -- Test 2: Verificar total de hábitos disponibles en la biblioteca
    SELECT COUNT(*) INTO total_habits_count
    FROM habits h
    WHERE h.is_active = true;

    RETURN QUERY SELECT 
        'Test 2: Hábitos disponibles en biblioteca'::TEXT,
        'INFO'::TEXT,
        format('Total de hábitos disponibles: %s', total_habits_count)::TEXT,
        total_habits_count;

    -- Test 3: Obtener sugerencias usando el stored procedure
    SELECT COUNT(*) INTO suggested_habits_count
    FROM get_popular_habit_suggestions(test_user_id, NULL, 20);

    RETURN QUERY SELECT 
        'Test 3: Sugerencias obtenidas'::TEXT,
        'INFO'::TEXT,
        format('Sugerencias devueltas: %s', suggested_habits_count)::TEXT,
        suggested_habits_count;

    -- Test 4: Verificar solapamiento (el problema principal)
    WITH user_existing_habits AS (
        SELECT DISTINCT habit_id 
        FROM user_habits 
        WHERE user_id = test_user_id AND is_active = true
    ),
    suggested_habits AS (
        SELECT * FROM get_popular_habit_suggestions(test_user_id, NULL, 20)
    )
    SELECT COUNT(*) INTO overlapping_habits_count
    FROM suggested_habits sh
    INNER JOIN user_existing_habits ueh ON sh.id = ueh.habit_id;

    RETURN QUERY SELECT 
        'Test 4: Verificar solapamiento'::TEXT,
        CASE WHEN overlapping_habits_count = 0 THEN 'PASS' ELSE 'FAIL' END::TEXT,
        format('Hábitos que se solapan: %s (debería ser 0)', overlapping_habits_count)::TEXT,
        overlapping_habits_count;

    -- Test 5: Mostrar detalles de los hábitos que se solapan
    IF overlapping_habits_count > 0 THEN
        RETURN QUERY
        WITH user_existing_habits AS (
            SELECT DISTINCT habit_id 
            FROM user_habits 
            WHERE user_id = test_user_id AND is_active = true
        ),
        suggested_habits AS (
            SELECT * FROM get_popular_habit_suggestions(test_user_id, NULL, 20)
        ),
        overlapping_details AS (
            SELECT 
                sh.id,
                sh.name
            FROM suggested_habits sh
            INNER JOIN user_existing_habits ueh ON sh.id = ueh.habit_id
        )
        SELECT 
            'Test 5: Hábitos problemáticos'::TEXT,
            'ERROR'::TEXT,
            format('Hábitos que aparecen en ambos: %s', STRING_AGG(od.name, ', '))::TEXT,
            overlapping_habits_count
        FROM overlapping_details od;
    END IF;

    -- Test 6: Verificar duplicados en user_habits para este usuario
    WITH duplicates AS (
        SELECT 
            habit_id,
            COUNT(*) as dup_count
        FROM user_habits 
        WHERE user_id = test_user_id
        GROUP BY habit_id 
        HAVING COUNT(*) > 1
    )
    SELECT COUNT(*) INTO overlapping_habits_count FROM duplicates;

    RETURN QUERY SELECT 
        'Test 6: Duplicados en user_habits'::TEXT,
        CASE WHEN overlapping_habits_count = 0 THEN 'PASS' ELSE 'WARNING' END::TEXT,
        format('Hábitos duplicados para este usuario: %s', overlapping_habits_count)::TEXT,
        overlapping_habits_count;

END;
$$;

-- Función para ejecutar pruebas automáticas con el primer usuario que tenga hábitos
CREATE OR REPLACE FUNCTION run_automatic_habit_suggestions_test()
RETURNS TABLE(
    test_step TEXT,
    status TEXT,
    details TEXT,
    count_value INTEGER
) 
LANGUAGE plpgsql
AS $$
DECLARE
    test_user_id UUID;
BEGIN
    -- Buscar un usuario existente con hábitos activos
    SELECT DISTINCT user_id INTO test_user_id
    FROM user_habits 
    WHERE is_active = true 
    LIMIT 1;

    IF test_user_id IS NOT NULL THEN
        RETURN QUERY SELECT * FROM test_habit_suggestions_detailed(test_user_id);
    ELSE
        RETURN QUERY SELECT 
            'Test Setup'::TEXT,
            'SKIP'::TEXT,
            'No hay usuarios con hábitos activos para probar'::TEXT,
            0;
    END IF;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION test_habit_suggestions_detailed(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION run_automatic_habit_suggestions_test() TO authenticated;

-- Comentarios
COMMENT ON FUNCTION test_habit_suggestions_detailed(UUID) IS 'Prueba detallada de sugerencias de hábitos para un usuario específico';
COMMENT ON FUNCTION run_automatic_habit_suggestions_test() IS 'Ejecuta pruebas automáticas detalladas de sugerencias de hábitos';

-- Instrucciones de uso:
-- 1. Ejecutar prueba automática: SELECT * FROM run_automatic_habit_suggestions_test();
-- 2. Probar con usuario específico: SELECT * FROM test_habit_suggestions_detailed('user-uuid-here');