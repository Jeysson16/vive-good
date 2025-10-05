-- Migración para corregir tabla conversations y agregar métricas de salud
-- Esta migración asegura que todas las columnas necesarias existan

-- 1. Crear o corregir tabla conversations
CREATE TABLE IF NOT EXISTS conversations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) DEFAULT 'Nueva conversación',
    content TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    last_message TEXT,
    last_message_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}'
);

-- 2. Agregar columnas faltantes si no existen
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS title VARCHAR(255) DEFAULT 'Nueva conversación';
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS last_message TEXT;
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS last_message_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';

-- 3. Crear tabla para métricas de síntomas y conocimiento
CREATE TABLE IF NOT EXISTS user_symptoms_knowledge (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    symptom_type VARCHAR(100) NOT NULL,
    knowledge_level VARCHAR(50) NOT NULL, -- 'bajo', 'medio', 'alto'
    risk_factors_identified TEXT[],
    symptoms_mentioned TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'
);

-- 4. Crear tabla para hábitos alimenticios de riesgo
CREATE TABLE IF NOT EXISTS user_eating_habits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    habit_type VARCHAR(100) NOT NULL,
    risk_level VARCHAR(50) NOT NULL, -- 'bajo', 'medio', 'alto'
    frequency VARCHAR(50), -- 'diario', 'semanal', 'ocasional'
    habits_identified TEXT[],
    recommendations_given TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'
);

-- 5. Crear tabla para adopción de hábitos saludables
CREATE TABLE IF NOT EXISTS user_healthy_habits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    habit_category VARCHAR(100) NOT NULL, -- 'alimentacion', 'ejercicio', 'sueno', 'estres'
    adoption_status VARCHAR(50) NOT NULL, -- 'adoptado', 'en_proceso', 'rechazado'
    commitment_level VARCHAR(50), -- 'bajo', 'medio', 'alto'
    habits_adopted TEXT[],
    barriers_identified TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'
);

-- 6. Crear tabla para aceptación de herramientas tecnológicas
CREATE TABLE IF NOT EXISTS user_tech_acceptance (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
    tool_type VARCHAR(100) NOT NULL, -- 'chat_bot', 'recordatorios', 'seguimiento'
    acceptance_level VARCHAR(50) NOT NULL, -- 'alta', 'media', 'baja'
    usage_frequency VARCHAR(50), -- 'diario', 'semanal', 'ocasional'
    feedback_sentiment VARCHAR(50), -- 'positivo', 'neutral', 'negativo'
    features_used TEXT[],
    suggestions_given TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'
);

-- 7. Habilitar RLS en todas las tablas
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_symptoms_knowledge ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_eating_habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_healthy_habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_tech_acceptance ENABLE ROW LEVEL SECURITY;

-- 8. Crear políticas RLS para conversations
DROP POLICY IF EXISTS "Users can view their own conversations" ON conversations;
DROP POLICY IF EXISTS "Users can create their own conversations" ON conversations;
DROP POLICY IF EXISTS "Users can update their own conversations" ON conversations;
DROP POLICY IF EXISTS "Users can delete their own conversations" ON conversations;

CREATE POLICY "Users can view their own conversations" ON conversations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own conversations" ON conversations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own conversations" ON conversations
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own conversations" ON conversations
    FOR DELETE USING (auth.uid() = user_id);

-- 9. Crear políticas RLS para tablas de métricas
CREATE POLICY "Users can view their own symptoms knowledge" ON user_symptoms_knowledge
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own symptoms knowledge" ON user_symptoms_knowledge
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own eating habits" ON user_eating_habits
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own eating habits" ON user_eating_habits
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own healthy habits" ON user_healthy_habits
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own healthy habits" ON user_healthy_habits
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own healthy habits" ON user_healthy_habits
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own tech acceptance" ON user_tech_acceptance
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own tech acceptance" ON user_tech_acceptance
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 10. Crear función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 11. Crear triggers para updated_at
DROP TRIGGER IF EXISTS update_conversations_updated_at ON conversations;
DROP TRIGGER IF EXISTS update_healthy_habits_updated_at ON user_healthy_habits;

CREATE TRIGGER update_conversations_updated_at 
    BEFORE UPDATE ON conversations
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_healthy_habits_updated_at 
    BEFORE UPDATE ON user_healthy_habits
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 12. Crear índices para optimización
CREATE INDEX IF NOT EXISTS idx_conversations_user_id ON conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_conversations_created_at ON conversations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversations_is_active ON conversations(is_active);
CREATE INDEX IF NOT EXISTS idx_conversations_updated_at ON conversations(updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_symptoms_knowledge_user_id ON user_symptoms_knowledge(user_id);
CREATE INDEX IF NOT EXISTS idx_symptoms_knowledge_conversation_id ON user_symptoms_knowledge(conversation_id);
CREATE INDEX IF NOT EXISTS idx_symptoms_knowledge_created_at ON user_symptoms_knowledge(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_eating_habits_user_id ON user_eating_habits(user_id);
CREATE INDEX IF NOT EXISTS idx_eating_habits_conversation_id ON user_eating_habits(conversation_id);
CREATE INDEX IF NOT EXISTS idx_eating_habits_created_at ON user_eating_habits(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_healthy_habits_user_id ON user_healthy_habits(user_id);
CREATE INDEX IF NOT EXISTS idx_healthy_habits_conversation_id ON user_healthy_habits(conversation_id);
CREATE INDEX IF NOT EXISTS idx_healthy_habits_created_at ON user_healthy_habits(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_tech_acceptance_user_id ON user_tech_acceptance(user_id);
CREATE INDEX IF NOT EXISTS idx_tech_acceptance_conversation_id ON user_tech_acceptance(conversation_id);
CREATE INDEX IF NOT EXISTS idx_tech_acceptance_created_at ON user_tech_acceptance(created_at DESC);

-- 13. Otorgar permisos
GRANT ALL PRIVILEGES ON conversations TO authenticated;
GRANT ALL PRIVILEGES ON user_symptoms_knowledge TO authenticated;
GRANT ALL PRIVILEGES ON user_eating_habits TO authenticated;
GRANT ALL PRIVILEGES ON user_healthy_habits TO authenticated;
GRANT ALL PRIVILEGES ON user_tech_acceptance TO authenticated;

GRANT SELECT ON conversations TO anon;

-- 14. Comentarios para documentación
COMMENT ON TABLE conversations IS 'Conversaciones del usuario con el asistente de salud';
COMMENT ON TABLE user_symptoms_knowledge IS 'Registro del conocimiento del usuario sobre síntomas y factores de riesgo';
COMMENT ON TABLE user_eating_habits IS 'Registro de hábitos alimenticios de riesgo identificados';
COMMENT ON TABLE user_healthy_habits IS 'Registro de adopción de hábitos de vida saludables';
COMMENT ON TABLE user_tech_acceptance IS 'Registro de aceptación de herramientas tecnológicas';

SELECT 'Migración 031 completada: tabla conversations corregida y tablas de métricas creadas' as resultado;