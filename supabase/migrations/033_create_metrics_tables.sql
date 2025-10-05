-- Tabla para registrar el conocimiento sobre síntomas y factores de riesgo
CREATE TABLE IF NOT EXISTS user_symptoms_knowledge (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    conversation_id UUID,
    symptoms_identified TEXT[], -- Array de síntomas identificados
    risk_factors_mentioned TEXT[], -- Array de factores de riesgo mencionados
    knowledge_level INTEGER CHECK (knowledge_level >= 1 AND knowledge_level <= 5), -- 1-5 escala
    confidence_score DECIMAL(3,2) CHECK (confidence_score >= 0 AND confidence_score <= 1),
    extracted_from_text TEXT, -- Texto original del que se extrajo la información
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla para registrar la aceptación de herramientas tecnológicas
CREATE TABLE IF NOT EXISTS user_tech_acceptance (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    conversation_id UUID,
    tool_mentioned VARCHAR(100), -- Nombre de la herramienta mencionada
    acceptance_level INTEGER CHECK (acceptance_level >= 1 AND acceptance_level <= 5), -- 1-5 escala
    sentiment VARCHAR(20) CHECK (sentiment IN ('positive', 'negative', 'neutral')),
    usage_frequency VARCHAR(20) CHECK (usage_frequency IN ('never', 'rarely', 'sometimes', 'often', 'always')),
    barriers_mentioned TEXT[], -- Barreras mencionadas para el uso
    benefits_mentioned TEXT[], -- Beneficios mencionados
    extracted_from_text TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla para registrar hábitos alimenticios de riesgo
CREATE TABLE IF NOT EXISTS user_eating_habits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    conversation_id UUID,
    habit_type VARCHAR(50), -- 'risk' o 'healthy'
    habit_description TEXT,
    frequency VARCHAR(20) CHECK (frequency IN ('never', 'rarely', 'sometimes', 'often', 'daily')),
    meal_time VARCHAR(20) CHECK (meal_time IN ('breakfast', 'lunch', 'dinner', 'snack', 'late_night')),
    food_categories TEXT[], -- Array de categorías de comida
    risk_level INTEGER CHECK (risk_level >= 1 AND risk_level <= 5), -- 1-5 escala
    extracted_from_text TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla para registrar adopción de hábitos de vida saludables
CREATE TABLE IF NOT EXISTS user_healthy_habits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    conversation_id UUID,
    habit_category VARCHAR(50), -- 'exercise', 'sleep', 'stress_management', 'nutrition', 'hydration'
    habit_description TEXT,
    adoption_status VARCHAR(20) CHECK (adoption_status IN ('planning', 'starting', 'maintaining', 'struggling', 'abandoned')),
    frequency VARCHAR(20) CHECK (frequency IN ('never', 'rarely', 'sometimes', 'often', 'daily')),
    duration_weeks INTEGER, -- Cuántas semanas lleva con el hábito
    barriers TEXT[], -- Barreras para mantener el hábito
    motivations TEXT[], -- Motivaciones para el hábito
    extracted_from_text TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla para registrar análisis de conversaciones
CREATE TABLE IF NOT EXISTS conversation_analysis (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id UUID,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    gemini_response TEXT, -- Respuesta completa de Gemini
    dl_model_response JSONB, -- Respuesta del modelo de deep learning
    extracted_metrics JSONB, -- Métricas extraídas en formato JSON
    sentiment_analysis JSONB, -- Análisis de sentimiento
    key_topics TEXT[], -- Temas principales identificados
    action_items TEXT[], -- Acciones recomendadas
    follow_up_needed BOOLEAN DEFAULT false,
    processing_status VARCHAR(20) DEFAULT 'pending' CHECK (processing_status IN ('pending', 'processing', 'completed', 'failed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para optimizar consultas
CREATE INDEX IF NOT EXISTS idx_user_symptoms_knowledge_user_id ON user_symptoms_knowledge(user_id);
CREATE INDEX IF NOT EXISTS idx_user_symptoms_knowledge_created_at ON user_symptoms_knowledge(created_at);
CREATE INDEX IF NOT EXISTS idx_user_tech_acceptance_user_id ON user_tech_acceptance(user_id);
CREATE INDEX IF NOT EXISTS idx_user_tech_acceptance_tool ON user_tech_acceptance(tool_mentioned);
CREATE INDEX IF NOT EXISTS idx_user_eating_habits_user_id ON user_eating_habits(user_id);
CREATE INDEX IF NOT EXISTS idx_user_eating_habits_type ON user_eating_habits(habit_type);
CREATE INDEX IF NOT EXISTS idx_user_healthy_habits_user_id ON user_healthy_habits(user_id);
CREATE INDEX IF NOT EXISTS idx_user_healthy_habits_category ON user_healthy_habits(habit_category);
CREATE INDEX IF NOT EXISTS idx_conversation_analysis_user_id ON conversation_analysis(user_id);
CREATE INDEX IF NOT EXISTS idx_conversation_analysis_status ON conversation_analysis(processing_status);

-- Políticas de seguridad RLS
ALTER TABLE user_symptoms_knowledge ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_tech_acceptance ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_eating_habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_healthy_habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_analysis ENABLE ROW LEVEL SECURITY;

-- Políticas para que los usuarios solo vean sus propios datos
CREATE POLICY "Users can view own symptoms knowledge" ON user_symptoms_knowledge
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own symptoms knowledge" ON user_symptoms_knowledge
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own tech acceptance" ON user_tech_acceptance
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own tech acceptance" ON user_tech_acceptance
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own eating habits" ON user_eating_habits
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own eating habits" ON user_eating_habits
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own healthy habits" ON user_healthy_habits
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own healthy habits" ON user_healthy_habits
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own conversation analysis" ON conversation_analysis
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own conversation analysis" ON conversation_analysis
    FOR INSERT WITH CHECK (auth.uid() = user_id);