-- Crear tabla para registrar hábitos alimenticios de riesgo
-- Esta tabla almacena la evaluación final de hábitos de riesgo después de usar la aplicación

CREATE TABLE IF NOT EXISTS habitos_alimenticios_riesgo (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  habitos jsonb NOT NULL DEFAULT '[]'::jsonb,
  total_riesgo integer NOT NULL DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- Habilitar RLS (Row Level Security)
ALTER TABLE habitos_alimenticios_riesgo ENABLE ROW LEVEL SECURITY;

-- Política para que los usuarios solo puedan ver sus propios registros
CREATE POLICY "Users can view their own habitos_alimenticios_riesgo" ON habitos_alimenticios_riesgo
  FOR SELECT USING (auth.uid() = user_id);

-- Política para que los usuarios puedan insertar sus propios registros
CREATE POLICY "Users can insert their own habitos_alimenticios_riesgo" ON habitos_alimenticios_riesgo
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Política para que los usuarios puedan actualizar sus propios registros
CREATE POLICY "Users can update their own habitos_alimenticios_riesgo" ON habitos_alimenticios_riesgo
  FOR UPDATE USING (auth.uid() = user_id);

-- Política para que los usuarios puedan eliminar sus propios registros
CREATE POLICY "Users can delete their own habitos_alimenticios_riesgo" ON habitos_alimenticios_riesgo
  FOR DELETE USING (auth.uid() = user_id);

-- Otorgar permisos a los roles anon y authenticated
GRANT SELECT, INSERT, UPDATE, DELETE ON habitos_alimenticios_riesgo TO authenticated;
GRANT SELECT ON habitos_alimenticios_riesgo TO anon;

-- Crear índice para mejorar el rendimiento de las consultas por user_id
CREATE INDEX IF NOT EXISTS idx_habitos_alimenticios_riesgo_user_id ON habitos_alimenticios_riesgo(user_id);

-- Crear índice para mejorar el rendimiento de las consultas por fecha
CREATE INDEX IF NOT EXISTS idx_habitos_alimenticios_riesgo_created_at ON habitos_alimenticios_riesgo(created_at);

-- Función para actualizar el campo updated_at automáticamente
CREATE OR REPLACE FUNCTION update_habitos_alimenticios_riesgo_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar updated_at automáticamente
CREATE TRIGGER update_habitos_alimenticios_riesgo_updated_at_trigger
  BEFORE UPDATE ON habitos_alimenticios_riesgo
  FOR EACH ROW
  EXECUTE FUNCTION update_habitos_alimenticios_riesgo_updated_at();

-- Comentarios para documentar la tabla
COMMENT ON TABLE habitos_alimenticios_riesgo IS 'Tabla para almacenar la evaluación de hábitos alimenticios de riesgo después de usar la aplicación';
COMMENT ON COLUMN habitos_alimenticios_riesgo.id IS 'Identificador único del registro';
COMMENT ON COLUMN habitos_alimenticios_riesgo.user_id IS 'ID del usuario que realizó la evaluación';
COMMENT ON COLUMN habitos_alimenticios_riesgo.habitos IS 'Array JSON con los hábitos de riesgo seleccionados';
COMMENT ON COLUMN habitos_alimenticios_riesgo.total_riesgo IS 'Número total de hábitos de riesgo seleccionados';
COMMENT ON COLUMN habitos_alimenticios_riesgo.created_at IS 'Fecha y hora de creación del registro';
COMMENT ON COLUMN habitos_alimenticios_riesgo.updated_at IS 'Fecha y hora de última actualización del registro';