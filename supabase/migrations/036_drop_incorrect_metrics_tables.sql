-- Eliminar tablas incorrectas de métricas que no deben existir
-- Las métricas deben calcularse dinámicamente basándose en user_habits, user_habit_logs y categories

-- Eliminar políticas primero
DROP POLICY IF EXISTS "Users can view own symptoms knowledge" ON user_symptoms_knowledge;
DROP POLICY IF EXISTS "Users can insert own symptoms knowledge" ON user_symptoms_knowledge;
DROP POLICY IF EXISTS "Users can view own tech acceptance" ON user_tech_acceptance;
DROP POLICY IF EXISTS "Users can insert own tech acceptance" ON user_tech_acceptance;
DROP POLICY IF EXISTS "Users can view own eating habits" ON user_eating_habits;
DROP POLICY IF EXISTS "Users can insert own eating habits" ON user_eating_habits;
DROP POLICY IF EXISTS "Users can view own healthy habits" ON user_healthy_habits;
DROP POLICY IF EXISTS "Users can insert own healthy habits" ON user_healthy_habits;
DROP POLICY IF EXISTS "Users can view own conversation analysis" ON conversation_analysis;
DROP POLICY IF EXISTS "Users can insert own conversation analysis" ON conversation_analysis;

-- Eliminar índices
DROP INDEX IF EXISTS idx_user_symptoms_knowledge_user_id;
DROP INDEX IF EXISTS idx_user_symptoms_knowledge_created_at;
DROP INDEX IF EXISTS idx_user_tech_acceptance_user_id;
DROP INDEX IF EXISTS idx_user_tech_acceptance_tool;
DROP INDEX IF EXISTS idx_user_eating_habits_user_id;
DROP INDEX IF EXISTS idx_user_eating_habits_type;
DROP INDEX IF EXISTS idx_user_healthy_habits_user_id;
DROP INDEX IF EXISTS idx_user_healthy_habits_category;
DROP INDEX IF EXISTS idx_conversation_analysis_user_id;
DROP INDEX IF EXISTS idx_conversation_analysis_status;

-- Eliminar tablas
DROP TABLE IF EXISTS user_symptoms_knowledge CASCADE;
DROP TABLE IF EXISTS user_tech_acceptance CASCADE;
DROP TABLE IF EXISTS user_eating_habits CASCADE;
DROP TABLE IF EXISTS user_healthy_habits CASCADE;
DROP TABLE IF EXISTS conversation_analysis CASCADE;

-- Comentario explicativo
COMMENT ON SCHEMA public IS 'Las métricas de progreso se calculan dinámicamente usando stored procedures basándose en user_habits, user_habit_logs, categories y habits';