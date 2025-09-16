-- Crear tabla habit_schedules para gestionar horarios específicos de hábitos
CREATE TABLE habit_schedules (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    habit_id UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
    scheduled_time TIME NOT NULL, -- Hora específica del día (HH:mm)
    scheduled_date DATE, -- Fecha específica (opcional para horarios recurrentes)
    recurrence_type VARCHAR(20) DEFAULT 'none' CHECK (recurrence_type IN ('none', 'daily', 'weekly', 'monthly')),
    recurrence_days INTEGER[], -- Días de la semana para recurrencia semanal (1=lunes, 7=domingo)
    is_active BOOLEAN DEFAULT true,
    notification_enabled BOOLEAN DEFAULT false,
    notification_minutes INTEGER DEFAULT 15, -- Minutos antes para notificar
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear índices para mejorar el rendimiento
CREATE INDEX idx_habit_schedules_user_id ON habit_schedules(user_id);
CREATE INDEX idx_habit_schedules_habit_id ON habit_schedules(habit_id);
CREATE INDEX idx_habit_schedules_time ON habit_schedules(scheduled_time);
CREATE INDEX idx_habit_schedules_date ON habit_schedules(scheduled_date);
CREATE INDEX idx_habit_schedules_active ON habit_schedules(is_active);

-- Habilitar RLS (Row Level Security)
ALTER TABLE habit_schedules ENABLE ROW LEVEL SECURITY;

-- Política para que los usuarios solo puedan ver sus propios horarios
CREATE POLICY "Users can view their own habit schedules" ON habit_schedules
    FOR SELECT USING (auth.uid() = user_id);

-- Política para que los usuarios solo puedan insertar sus propios horarios
CREATE POLICY "Users can insert their own habit schedules" ON habit_schedules
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Política para que los usuarios solo puedan actualizar sus propios horarios
CREATE POLICY "Users can update their own habit schedules" ON habit_schedules
    FOR UPDATE USING (auth.uid() = user_id);

-- Política para que los usuarios solo puedan eliminar sus propios horarios
CREATE POLICY "Users can delete their own habit schedules" ON habit_schedules
    FOR DELETE USING (auth.uid() = user_id);

-- Trigger para actualizar updated_at automáticamente
CREATE TRIGGER update_habit_schedules_updated_at
    BEFORE UPDATE ON habit_schedules
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Conceder permisos a los roles anon y authenticated
GRANT SELECT, INSERT, UPDATE, DELETE ON habit_schedules TO authenticated;
GRANT SELECT ON habit_schedules TO anon;

-- Comentarios para documentar la tabla
COMMENT ON TABLE habit_schedules IS 'Tabla para gestionar horarios específicos de hábitos del usuario';
COMMENT ON COLUMN habit_schedules.scheduled_time IS 'Hora específica del día en formato HH:mm';
COMMENT ON COLUMN habit_schedules.recurrence_days IS 'Array de días de la semana para recurrencia (1=lunes, 7=domingo)';
COMMENT ON COLUMN habit_schedules.notification_minutes IS 'Minutos antes del horario para enviar notificación';