-- Agregar columnas de texto para las respuestas del usuario en user_symptoms_knowledge
ALTER TABLE user_symptoms_knowledge 
ADD COLUMN IF NOT EXISTS symptoms_response TEXT,
ADD COLUMN IF NOT EXISTS risk_factors_response TEXT,
ADD COLUMN IF NOT EXISTS prevention_response TEXT,
ADD COLUMN IF NOT EXISTS identified_symptoms TEXT[],
ADD COLUMN IF NOT EXISTS identified_risk_factors TEXT[],
ADD COLUMN IF NOT EXISTS identified_prevention TEXT[];

-- Comentarios para documentar las nuevas columnas
COMMENT ON COLUMN user_symptoms_knowledge.symptoms_response IS 'Respuesta del usuario sobre síntomas de gastritis';
COMMENT ON COLUMN user_symptoms_knowledge.risk_factors_response IS 'Respuesta del usuario sobre factores de riesgo';
COMMENT ON COLUMN user_symptoms_knowledge.prevention_response IS 'Respuesta del usuario sobre medidas de prevención';
COMMENT ON COLUMN user_symptoms_knowledge.identified_symptoms IS 'Array de síntomas identificados correctamente por el sistema';
COMMENT ON COLUMN user_symptoms_knowledge.identified_risk_factors IS 'Array de factores de riesgo identificados correctamente';
COMMENT ON COLUMN user_symptoms_knowledge.identified_prevention IS 'Array de medidas de prevención identificadas correctamente';