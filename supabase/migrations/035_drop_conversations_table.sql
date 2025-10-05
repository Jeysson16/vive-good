-- Migración para eliminar la tabla conversations y todas sus dependencias
-- Usar chat_sessions como la tabla principal para el historial de chats

-- 1. Eliminar funciones relacionadas con conversations
DROP FUNCTION IF EXISTS record_conversation_metrics(UUID, UUID, JSONB, JSONB, JSONB, JSONB) CASCADE;
DROP FUNCTION IF EXISTS get_conversation_summary(UUID) CASCADE;
DROP FUNCTION IF EXISTS update_conversation_status(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS get_user_conversations(UUID) CASCADE;

-- 2. Eliminar triggers relacionados con conversations
DROP TRIGGER IF EXISTS update_conversations_updated_at ON conversations CASCADE;
DROP TRIGGER IF EXISTS conversations_audit_trigger ON conversations CASCADE;

-- 3. Eliminar vistas relacionadas con conversations
DROP VIEW IF EXISTS conversation_metrics_view CASCADE;
DROP VIEW IF EXISTS user_conversation_summary CASCADE;

-- 4. Eliminar índices específicos de conversations
DROP INDEX IF EXISTS idx_conversations_user_id CASCADE;
DROP INDEX IF EXISTS idx_conversations_status CASCADE;
DROP INDEX IF EXISTS idx_conversations_created_at CASCADE;
DROP INDEX IF EXISTS idx_conversations_updated_at CASCADE;

-- 5. Eliminar políticas RLS de conversations
DROP POLICY IF EXISTS "Users can view their own conversations" ON conversations;
DROP POLICY IF EXISTS "Users can insert their own conversations" ON conversations;
DROP POLICY IF EXISTS "Users can update their own conversations" ON conversations;
DROP POLICY IF EXISTS "Users can delete their own conversations" ON conversations;

-- 6. Eliminar la tabla conversations y todas sus dependencias
DROP TABLE IF EXISTS conversations CASCADE;

-- 7. Verificar que chat_sessions tiene las columnas necesarias
-- Si no existe la columna status, la agregamos
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'chat_sessions' AND column_name = 'status') THEN
        ALTER TABLE chat_sessions ADD COLUMN status TEXT DEFAULT 'active';
    END IF;
END $$;

-- 8. Si no existe la columna summary, la agregamos
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'chat_sessions' AND column_name = 'summary') THEN
        ALTER TABLE chat_sessions ADD COLUMN summary TEXT;
    END IF;
END $$;

-- 9. Crear función para obtener resumen de sesión de chat
CREATE OR REPLACE FUNCTION get_chat_session_summary(session_id_param UUID)
RETURNS TABLE(
    session_id UUID,
    title TEXT,
    summary TEXT,
    message_count BIGINT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cs.id,
        cs.title,
        cs.summary,
        COUNT(cm.id) as message_count,
        cs.created_at,
        cs.updated_at
    FROM chat_sessions cs
    LEFT JOIN chat_messages cm ON cs.id = cm.session_id
    WHERE cs.id = session_id_param
    GROUP BY cs.id, cs.title, cs.summary, cs.created_at, cs.updated_at;
END;
$$;

-- 10. Crear función para actualizar estado de sesión de chat
CREATE OR REPLACE FUNCTION update_chat_session_status(session_id_param UUID, status_param TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE chat_sessions 
    SET status = status_param, updated_at = NOW()
    WHERE id = session_id_param;
    
    RETURN FOUND;
END;
$$;

-- 11. Crear función para obtener sesiones de chat del usuario
CREATE OR REPLACE FUNCTION get_user_chat_sessions(user_id_param UUID)
RETURNS TABLE(
    session_id UUID,
    title TEXT,
    status TEXT,
    message_count BIGINT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cs.id,
        cs.title,
        cs.status,
        COUNT(cm.id) as message_count,
        cs.created_at,
        cs.updated_at
    FROM chat_sessions cs
    LEFT JOIN chat_messages cm ON cs.id = cm.session_id
    WHERE cs.user_id = user_id_param
    GROUP BY cs.id, cs.title, cs.status, cs.created_at, cs.updated_at
    ORDER BY cs.updated_at DESC;
END;
$$;

-- 12. Crear vista para métricas de sesiones de chat
CREATE OR REPLACE VIEW chat_session_metrics_view AS
SELECT 
    cs.id as session_id,
    cs.user_id,
    cs.title,
    cs.status,
    COUNT(cm.id) as message_count,
    cs.created_at,
    cs.updated_at,
    -- Métricas agregadas
    COALESCE(sk.knowledge_level, 0) as symptoms_knowledge_level,
    COALESCE(eh.nutrition_score, 0) as eating_habits_score,
    COALESCE(hh.wellness_score, 0) as healthy_habits_score,
    COALESCE(ta.acceptance_score, 0) as tech_acceptance_score
FROM chat_sessions cs
LEFT JOIN chat_messages cm ON cs.id = cm.session_id
LEFT JOIN user_symptoms_knowledge sk ON cs.id = sk.session_id
LEFT JOIN user_eating_habits eh ON cs.id = eh.session_id
LEFT JOIN user_healthy_habits hh ON cs.id = hh.session_id
LEFT JOIN user_tech_acceptance ta ON cs.id = ta.session_id
GROUP BY cs.id, cs.user_id, cs.title, cs.status, cs.created_at, cs.updated_at,
         sk.knowledge_level, eh.nutrition_score, hh.wellness_score, ta.acceptance_score;

-- 13. Otorgar permisos a las funciones
GRANT EXECUTE ON FUNCTION get_chat_session_summary(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION update_chat_session_status(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_chat_sessions(UUID) TO authenticated;

-- 14. Otorgar permisos a la vista
GRANT SELECT ON chat_session_metrics_view TO authenticated;

SELECT 'Migración 035 completada: tabla conversations eliminada, funciones migradas a chat_sessions' as resultado;