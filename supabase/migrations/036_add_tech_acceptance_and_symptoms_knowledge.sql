-- Agregar columna accepts_tech_tools a la tabla app_ratings
ALTER TABLE app_ratings ADD COLUMN IF NOT EXISTS accepts_tech_tools BOOLEAN DEFAULT false;

-- Crear tabla para conocimiento de síntomas y factores de riesgo
CREATE TABLE IF NOT EXISTS user_symptoms_knowledge (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  knowledge_level INTEGER NOT NULL CHECK (knowledge_level >= 1 AND knowledge_level <= 5),
  presents_knowledge BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Habilitar RLS (Row Level Security) para user_symptoms_knowledge
ALTER TABLE user_symptoms_knowledge ENABLE ROW LEVEL SECURITY;

-- Políticas para user_symptoms_knowledge
CREATE POLICY "Users can view their own symptoms knowledge" ON user_symptoms_knowledge
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own symptoms knowledge" ON user_symptoms_knowledge
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own symptoms knowledge" ON user_symptoms_knowledge
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own symptoms knowledge" ON user_symptoms_knowledge
  FOR DELETE USING (auth.uid() = user_id);

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_user_symptoms_knowledge_user_id ON user_symptoms_knowledge(user_id);
CREATE INDEX IF NOT EXISTS idx_user_symptoms_knowledge_created_at ON user_symptoms_knowledge(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_symptoms_knowledge_level ON user_symptoms_knowledge(knowledge_level);

-- Trigger para actualizar updated_at automáticamente en user_symptoms_knowledge
CREATE TRIGGER update_user_symptoms_knowledge_updated_at 
    BEFORE UPDATE ON user_symptoms_knowledge 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Comentarios para documentar las tablas
COMMENT ON TABLE app_ratings IS 'Tabla para almacenar las calificaciones de aceptación tecnológica de los usuarios';
COMMENT ON COLUMN app_ratings.accepts_tech_tools IS 'Indica si el usuario acepta el uso de herramientas tecnológicas';

COMMENT ON TABLE user_symptoms_knowledge IS 'Tabla para almacenar el nivel de conocimiento sobre síntomas y factores de riesgo';
COMMENT ON COLUMN user_symptoms_knowledge.knowledge_level IS 'Nivel de conocimiento del 1 al 5 según criterios específicos';
COMMENT ON COLUMN user_symptoms_knowledge.presents_knowledge IS 'Indica si el usuario presenta conocimiento sobre síntomas';