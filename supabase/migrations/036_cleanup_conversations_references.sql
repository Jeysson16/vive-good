-- Migración para asegurar funcionalidad completa de chat_sessions
-- Reemplaza completamente el sistema de conversations con chat_sessions

-- Eliminar funciones relacionadas con conversations si existen
DROP FUNCTION IF EXISTS get_conversation_summary(uuid) CASCADE;
DROP FUNCTION IF EXISTS update_conversation_status(uuid, text) CASCADE;
DROP FUNCTION IF EXISTS get_user_conversations(uuid) CASCADE;
DROP FUNCTION IF EXISTS create_conversation(uuid, text) CASCADE;
DROP FUNCTION IF EXISTS complete_conversation(uuid) CASCADE;

-- Eliminar vistas relacionadas con conversations si existen
DROP VIEW IF EXISTS conversation_metrics_view CASCADE;
DROP VIEW IF EXISTS user_conversation_summary CASCADE;

-- Asegurar que chat_sessions tenga las columnas necesarias
ALTER TABLE chat_sessions 
ADD COLUMN IF NOT EXISTS status text DEFAULT 'active',
ADD COLUMN IF NOT EXISTS summary text;

-- Crear índices para chat_sessions si no existen
CREATE INDEX IF NOT EXISTS idx_chat_sessions_user_id ON chat_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_status ON chat_sessions(status);
CREATE INDEX IF NOT EXISTS idx_chat_sessions_created_at ON chat_sessions(created_at);

-- Crear función para obtener resumen de sesión de chat
CREATE OR REPLACE FUNCTION get_chat_session_summary(session_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN (
    SELECT summary
    FROM chat_sessions
    WHERE id = session_id
  );
END;
$$;

-- Crear función para actualizar estado de sesión de chat
CREATE OR REPLACE FUNCTION update_chat_session_status(session_id uuid, new_status text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE chat_sessions
  SET status = new_status,
      updated_at = now()
  WHERE id = session_id;
END;
$$;

-- Crear función para obtener sesiones de chat del usuario
CREATE OR REPLACE FUNCTION get_user_chat_sessions(user_uuid uuid)
RETURNS TABLE(
  id uuid,
  title text,
  status text,
  created_at timestamptz,
  updated_at timestamptz,
  message_count bigint
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
    cs.created_at,
    cs.updated_at,
    COUNT(cm.id) as message_count
  FROM chat_sessions cs
  LEFT JOIN chat_messages cm ON cs.id = cm.session_id
  WHERE cs.user_id = user_uuid
  GROUP BY cs.id, cs.title, cs.status, cs.created_at, cs.updated_at
  ORDER BY cs.updated_at DESC;
END;
$$;

-- Crear vista para métricas de sesiones de chat
CREATE OR REPLACE VIEW chat_session_metrics_view AS
SELECT 
  cs.id as session_id,
  cs.user_id,
  cs.title,
  cs.status,
  cs.created_at,
  cs.updated_at,
  COUNT(cm.id) as message_count,
  MAX(cm.created_at) as last_message_at
FROM chat_sessions cs
LEFT JOIN chat_messages cm ON cs.id = cm.session_id
GROUP BY cs.id, cs.user_id, cs.title, cs.status, cs.created_at, cs.updated_at;

-- Otorgar permisos a las funciones
GRANT EXECUTE ON FUNCTION get_chat_session_summary(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION update_chat_session_status(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_chat_sessions(uuid) TO authenticated;

-- Otorgar permisos a la vista
GRANT SELECT ON chat_session_metrics_view TO authenticated;
GRANT SELECT ON chat_session_metrics_view TO anon;

-- Comentario de finalización
-- Esta migración limpia todas las referencias a conversations y asegura
-- que el sistema use completamente chat_sessions como reemplazo