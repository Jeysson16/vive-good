-- Script de prueba para verificar que las sugerencias de hábitos funcionan correctamente
-- Este script prueba que los hábitos ya existentes en user_habits NO aparezcan en las sugerencias

-- Función de prueba para verificar las sugerencias
CREATE OR REPLACE FUNCTION test_habit_suggestions_exclusion(test_user_id UUID)
RETURNS TABLE(
    test_name TEXT,
    status TEXT,
    details TEXT
) 
LANGUAGE plpgsql
AS $$
DECLARE
    user_habits_count INTEGER;
    suggested_habits_count INTEGER;
    overlapping_habits_count INTEGER;
    test_result TEXT;
BEGIN
    -- Test 1: Verificar que el usuario tiene hábitos
    SELECT COUNT(*) INTO user_habits_count
    FROM user_habits uh
    WHERE uh.user_id = test_user_id AND uh.is_active = true;

    IF user_habits_count = 0 THEN
        RETURN QUERY SELECT 
            'Test 1: Usuario tiene hábitos'::TEXT,
            'SKIP'::TEXT,
            format('Usuario %s no tiene hábitos activos para probar', test_user_id)::TEXT;
    ELSE
        RETURN QUERY SELECT 
            'Test 1: Usuario tiene hábitos'::TEXT,
            'PASS'::TEXT,
            format('Usuario tiene %s hábitos activos', user_habits_count)::TEXT;
    END IF;

    -- Test 2: Obtener sugerencias y verificar que no incluyen hábitos del usuario
    WITH user_existing_habits AS (
        SELECT DISTINCT habit_id 
        FROM user_habits 
        WHERE user_id = test_user_id AND is_active = true
    ),
    suggested_habits AS (
        SELECT * FROM get_popular_habit_suggestions(test_user_id, NULL, 20)
    )
    SELECT COUNT(*) INTO suggested_habits_count
    FROM suggested_habits;

    -- Test 3: Verificar que no hay solapamiento
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

    IF overlapping_habits_count = 0 THEN
        RETURN QUERY SELECT 
            'Test 2: Sin solapamiento'::TEXT,
            'PASS'::TEXT,
            format('✓ Ningún hábito sugerido (%s) está en user_habits (%s)', 
                   suggested_habits_count, user_habits_count)::TEXT;
    ELSE
        RETURN QUERY SELECT 
            'Test 2: Sin solapamiento'::TEXT,
            'FAIL'::TEXT,
            format('✗ %s hábitos sugeridos YA EXISTEN en user_habits', overlapping_habits_count)::TEXT;
    END IF;

    -- Test 4: Verificar detalles de los hábitos que se solapan (si los hay)
    IF overlapping_habits_count > 0 THEN
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
                sh.name,
                sh.category_id
            FROM suggested_habits sh
            INNER JOIN user_existing_habits ueh ON sh.id = ueh.habit_id
        )
        SELECT 
            STRING_AGG(od.name, ', ') INTO test_result
        FROM overlapping_details od;

        RETURN QUERY SELECT 
            'Test 3: Hábitos problemáticos'::TEXT,
            'INFO'::TEXT,
            format('Hábitos que aparecen en ambos: %s', test_result)::TEXT;
    END IF;

END;
$$;

-- Función para probar con un usuario específico o crear uno de prueba
CREATE OR REPLACE FUNCTION run_habit_suggestions_test()
RETURNS TABLE(
    test_name TEXT,
    status TEXT,
    details TEXT
) 
LANGUAGE plpgsql
AS $$
DECLARE
    test_user_id UUID;
    existing_user_id UUID;
BEGIN
    -- Buscar un usuario existente con hábitos
    SELECT DISTINCT user_id INTO existing_user_id
    FROM user_habits 
    WHERE is_active = true 
    LIMIT 1;

    IF existing_user_id IS NOT NULL THEN
        RETURN QUERY SELECT * FROM test_habit_suggestions_exclusion(existing_user_id);
    ELSE
        RETURN QUERY SELECT 
            'Test Setup'::TEXT,
            'SKIP'::TEXT,
            'No hay usuarios con hábitos activos para probar'::TEXT;
    END IF;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION test_habit_suggestions_exclusion(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION run_habit_suggestions_test() TO authenticated;

-- Comentarios
COMMENT ON FUNCTION test_habit_suggestions_exclusion(UUID) IS 'Prueba que las sugerencias no incluyan hábitos ya existentes del usuario';
COMMENT ON FUNCTION run_habit_suggestions_test() IS 'Ejecuta pruebas automáticas de sugerencias de hábitos';

-- Instrucciones de uso:
-- 1. Ejecutar prueba automática: SELECT * FROM run_habit_suggestions_test();
-- 2. Probar con usuario específico: SELECT * FROM test_habit_suggestions_exclusion('user-uuid-here')