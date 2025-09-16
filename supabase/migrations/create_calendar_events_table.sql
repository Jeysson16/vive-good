-- Crear tabla calendar_events para gestionar fechas, horarios y hábitos
CREATE TABLE calendar_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    habit_id UUID REFERENCES habits(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE,
    start_time TIME,
    end_time TIME,
    is_all_day BOOLEAN DEFAULT false,
    recurrence_type VARCHAR(20) CHECK (recurrence_type IN ('none', 'daily', 'weekly', 'monthly', 'yearly')),
    recurrence_interval INTEGER DEFAULT 1,
    recurrence_days INTEGER[], -- Para días de la semana (0=domingo, 1=lunes, etc.)
    recurrence_end_date DATE,
    reminder_minutes INTEGER DEFAULT 15,
    notification_enabled BOOLEAN DEFAULT true,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear índices para mejorar el rendimiento
CREATE INDEX idx_calendar_events_user_id ON calendar_events(user_id);
CREATE INDEX idx_calendar_events_habit_id ON calendar_events(habit_id);
CREATE INDEX idx_calendar_events_start_date ON calendar_events(start_date);
CREATE INDEX idx_calendar_events_dates ON calendar_events(start_date, end_date);

-- Habilitar RLS (Row Level Security)
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;

-- Política para que los usuarios solo puedan ver sus propios eventos
CREATE POLICY "Users can view their own calendar events" ON calendar_events
    FOR SELECT USING (auth.uid() = user_id);

-- Política para que los usuarios solo puedan insertar sus propios eventos
CREATE POLICY "Users can insert their own calendar events" ON calendar_events
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Política para que los usuarios solo puedan actualizar sus propios eventos
CREATE POLICY "Users can update their own calendar events" ON calendar_events
    FOR UPDATE USING (auth.uid() = user_id);

-- Política para que los usuarios solo puedan eliminar sus propios eventos
CREATE POLICY "Users can delete their own calendar events" ON calendar_events
    FOR DELETE USING (auth.uid() = user_id);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para actualizar updated_at automáticamente
CREATE TRIGGER update_calendar_events_updated_at
    BEFORE UPDATE ON calendar_events
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Conceder permisos a los roles anon y authenticated
GRANT SELECT, INSERT, UPDATE, DELETE ON calendar_events TO authenticated;
GRANT SELECT ON calendar_events TO anon;

-- Comentarios para documentar la tabla
COMMENT ON TABLE calendar_events IS 'Tabla para gestionar eventos de calendario relacionados con hábitos y recordatorios';
COMMENT ON COLUMN calendar_events.recurrence_days IS 'Array de días de la semana para recurrencia (0=domingo, 1=lunes, etc.)';
COMMENT ON COLUMN calendar_events.reminder_minutes IS 'Minutos antes del evento para enviar recordatorio';
COMMENT ON COLUMN calendar_events.is_all_day IS 'Indica si el evento dura todo el día';