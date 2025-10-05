-- Migración para actualizar las tablas de métricas
-- Cambiar conversation_id por session_id para usar chat_sessions

-- 1. Actualizar tabla user_symptoms_knowledge
ALTER TABLE user_symptoms_knowledge 
DROP COLUMN IF EXISTS conversation_id;

ALTER TABLE user_symptoms_knowledge 
ADD COLUMN session_id UUID REFERENCES chat_sessions(id) ON DELETE CASCADE;

-- 2. Actualizar tabla user_eating_habits
ALTER TABLE user_eating_habits 
DROP COLUMN IF EXISTS conversation_id;

ALTER TABLE user_eating_habits 
ADD COLUMN session_id UUID REFERENCES chat_sessions(id) ON DELETE CASCADE;

-- 3. Actualizar tabla user_healthy_habits
ALTER TABLE user_healthy_habits 
DROP COLUMN IF EXISTS conversation_id;

ALTER TABLE user_healthy_habits 
ADD COLUMN session_id UUID REFERENCES chat_sessions(id) ON DELETE CASCADE;

-- 4. Actualizar tabla user_tech_acceptance
ALTER TABLE user_tech_acceptance 
DROP COLUMN IF EXISTS conversation_id;

ALTER TABLE user_tech_acceptance 
ADD COLUMN session_id UUID REFERENCES chat_sessions(id) ON DELETE CASCADE;

-- 5. Actualizar tabla conversation_analysis si existe
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'conversation_analysis') THEN
        ALTER TABLE conversation_analysis 
        DROP COLUMN IF EXISTS conversation_id;
        
        ALTER TABLE conversation_analysis 
        ADD COLUMN session_id UUID REFERENCES chat_sessions(id) ON DELETE CASCADE;
    END IF;
END $$;

-- 6. Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_user_symptoms_knowledge_session_id ON user_symptoms_knowledge(session_id);
CREATE INDEX IF NOT EXISTS idx_user_eating_habits_session_id ON user_eating_habits(session_id);
CREATE INDEX IF NOT EXISTS idx_user_healthy_habits_session_id ON user_healthy_habits(session_id);
CREATE INDEX IF NOT EXISTS idx_user_tech_acceptance_session_id ON user_tech_acceptance(session_id);

-- 7. Actualizar políticas RLS si es necesario
-- Las políticas existentes deberían seguir funcionando ya que se basan en user_id

SELECT 'Migración 034 completada: tablas de métricas actualizadas para usar session_id' as resultado;