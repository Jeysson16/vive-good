-- Test para verificar exactamente qué campos retornan los stored procedures actuales
-- Objetivo: Identificar qué se rompió y qué campos están retornando

-- ========================================
-- 1. VERIFICAR DEFINICIONES DE FUNCIONES
-- ========================================

-- Ver definición completa de get_dashboard_habits
SELECT 
    'get_dashboard_habits DEFINITION:' as info,
    pg_get_function_arguments(oid) as arguments,
    pg_get_function_result(oid) as return_type
FROM pg_proc 
WHERE proname = 'get_dashboard_habits';

-- Ver definición completa de get_user_habits_with_details  
SELECT 
    'get_user_habits_with_details DEFINITION:' as info,
    pg_get_function_arguments(oid) as arguments,
    pg_get_function_result(oid) as return_type
FROM pg_proc 
WHERE proname = 'get_user_habits_with_details';

-- ========================================
-- 2. TEST get_dashboard_habits
-- ========================================

SELECT '========== TESTING get_dashboard_habits ==========' as test_section;

-- Ejecutar el stored procedure y mostrar TODOS los campos
SELECT * FROM get_dashboard_habits(
    p_user_id := '8e622f30-084d-4015-a3b8-6ae33e8ee991'::uuid,
    p_date := CURRENT_DATE
) LIMIT 3;

-- ========================================
-- 3. TEST get_user_habits_with_details
-- ========================================

SELECT '========== TESTING get_user_habits_with_details ==========' as test_section;

-- Ejecutar el stored procedure y mostrar TODOS los campos
SELECT * FROM get_user_habits_with_details(
    p_user_id := '8e622f30-084d-4015-a3b8-6ae33e8ee991'::uuid
) LIMIT 3;

-- ========================================
-- 4. VERIFICAR DATOS BASE PARA DEBUGGING
-- ========================================

SELECT '========== VERIFICAR DATOS BASE ==========' as test_section;

-- Verificar si el usuario de prueba tiene datos
SELECT 
    'USER_HABITS for test user:' as info,
    COUNT(*) as total_user_habits,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_user_habits
FROM user_habits 
WHERE user_id = '8e622f30-084d-4015-a3b8-6ae33e8ee991'::uuid;

-- Verificar hábitos base
SELECT 
    'HABITS table:' as info,
    COUNT(*) as total_habits,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_habits
FROM habits;

-- Verificar categorías
SELECT 
    'CATEGORIES table:' as info,
    COUNT(*) as total_categories
FROM categories;

-- ========================================
-- 5. COMPARAR CAMPOS ESPECÍFICOS DE ICONOS
-- ========================================

SELECT '========== COMPARAR CAMPOS DE ICONOS ==========' as test_section;

-- Mostrar algunos registros de cada SP para comparar estructura
SELECT 
    'Dashboard habits sample:' as source,
    user_habit_id,
    habit_name,
    category_name
FROM get_dashboard_habits(
    p_user_id := '8e622f30-084d-4015-a3b8-6ae33e8ee991'::uuid,
    p_date := CURRENT_DATE
) LIMIT 2;

SELECT 
    'User habits with details sample:' as source,
    user_habit_id,
    habit_name,
    category_name
FROM get_user_habits_with_details(
    p_user_id := '8e622f30-084d-4015-a3b8-6ae33e8ee991'::uuid
) LIMIT 2;