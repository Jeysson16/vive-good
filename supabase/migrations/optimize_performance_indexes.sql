-- =====================================================
-- ÍNDICES OPTIMIZADOS PARA MEJORAR RENDIMIENTO
-- Objetivo: Reducir tiempo de consultas de 20s a 2-3s
-- =====================================================

-- 1. ÍNDICES PARA USER_HABITS (tabla más consultada)
CREATE INDEX IF NOT EXISTS idx_user_habits_user_id_active 
ON user_habits(user_id, is_active) 
WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_user_habits_habit_id_user_id 
ON user_habits(habit_id, user_id);

-- 2. ÍNDICES PARA USER_HABIT_LOGS (tabla con más datos)
CREATE INDEX IF NOT EXISTS idx_user_habit_logs_user_habit_id_date 
ON user_habit_logs(user_habit_id, completed_at);

CREATE INDEX IF NOT EXISTS idx_user_habit_logs_date_status 
ON user_habit_logs(completed_at, status) 
WHERE status = 'completed';

CREATE INDEX IF NOT EXISTS idx_user_habit_logs_monthly 
ON user_habit_logs(user_habit_id, completed_at, status);

-- 3. ÍNDICES PARA HABITS
CREATE INDEX IF NOT EXISTS idx_habits_category_id 
ON habits(category_id);

-- 4. ÍNDICES PARA CATEGORIES
CREATE INDEX IF NOT EXISTS idx_categories_id_name 
ON categories(id, name);

-- 5. ÍNDICE PARA CONSULTAS DE FECHAS
CREATE INDEX IF NOT EXISTS idx_user_habit_logs_date_only 
ON user_habit_logs(completed_at) 
WHERE completed_at IS NOT NULL;

-- 6. ÍNDICE PARA CONSULTAS DE RANGO DE FECHAS
CREATE INDEX IF NOT EXISTS idx_user_habit_logs_date_range 
ON user_habit_logs(completed_at DESC, user_habit_id, status);

-- =====================================================
-- ESTADÍSTICAS Y ANÁLISIS
-- =====================================================

-- Actualizar estadísticas de las tablas para el optimizador
ANALYZE user_habits;
ANALYZE user_habit_logs;
ANALYZE habits;
ANALYZE categories;