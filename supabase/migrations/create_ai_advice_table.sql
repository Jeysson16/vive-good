-- Crear tabla para almacenar consejos de IA
CREATE TABLE IF NOT EXISTS ai_advice (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    habit_name VARCHAR(255) NOT NULL,
    habit_category VARCHAR(100),
    advice_text TEXT NOT NULL,
    advice_type VARCHAR(50) DEFAULT 'general', -- 'general', 'motivation', 'tips', 'schedule'
    source VARCHAR(50) DEFAULT 'ai', -- 'ai', 'gemini', 'manual'
    is_applied BOOLEAN DEFAULT FALSE, -- Si el usuario aplicó el consejo
    is_favorite BOOLEAN DEFAULT FALSE, -- Si el usuario marcó como favorito
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_ai_advice_user_id ON ai_advice(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_advice_habit_name ON ai_advice(habit_name);
CREATE INDEX IF NOT EXISTS idx_ai_advice_category ON ai_advice(habit_category);
CREATE INDEX IF NOT EXISTS idx_ai_advice_created_at ON ai_advice(created_at);
CREATE INDEX IF NOT EXISTS idx_ai_advice_is_favorite ON ai_advice(is_favorite);

-- Habilitar RLS (Row Level Security)
ALTER TABLE ai_advice ENABLE ROW LEVEL SECURITY;

-- Política para que los usuarios solo puedan ver sus propios consejos
CREATE POLICY "Users can view their own advice" ON ai_advice
    FOR SELECT USING (auth.uid() = user_id);

-- Política para que los usuarios puedan insertar sus propios consejos
CREATE POLICY "Users can insert their own advice" ON ai_advice
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Política para que los usuarios puedan actualizar sus propios consejos
CREATE POLICY "Users can update their own advice" ON ai_advice
    FOR UPDATE USING (auth.uid() = user_id);

-- Política para que los usuarios puedan eliminar sus propios consejos
CREATE POLICY "Users can delete their own advice" ON ai_advice
    FOR DELETE USING (auth.uid() = user_id);

-- Función para actualizar el timestamp de updated_at
CREATE OR REPLACE FUNCTION update_ai_advice_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar automáticamente updated_at
CREATE TRIGGER update_ai_advice_updated_at_trigger
    BEFORE UPDATE ON ai_advice
    FOR EACH ROW
    EXECUTE FUNCTION update_ai_advice_updated_at();

-- Comentarios para documentar la tabla
COMMENT ON TABLE ai_advice IS 'Almacena consejos generados por IA para hábitos de usuarios';
COMMENT ON COLUMN ai_advice.advice_type IS 'Tipo de consejo: general, motivation, tips, schedule';
COMMENT ON COLUMN ai_advice.source IS 'Fuente del consejo: ai, gemini, manual';
COMMENT ON COLUMN ai_advice.is_applied IS 'Indica si el usuario aplicó el consejo';
COMMENT ON COLUMN ai_advice.is_favorite IS 'Indica si el usuario marcó el consejo como favorito';