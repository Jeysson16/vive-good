-- Crear tabla notifications para gestionar notificaciones del usuario
CREATE TABLE notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT,
    type VARCHAR(50) NOT NULL CHECK (type IN ('habit_reminder', 'habit_completion', 'system', 'achievement', 'calendar_event')),
    related_id UUID, -- ID de la entidad relacionada (hábito, evento, etc.)
    data JSONB, -- Datos adicionales para la notificación
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP WITH TIME ZONE,
    scheduled_for TIMESTAMP WITH TIME ZONE, -- Cuándo debe enviarse la notificación
    sent_at TIMESTAMP WITH TIME ZONE, -- Cuándo se envió realmente la notificación
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear índices para mejorar el rendimiento
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_scheduled_for ON notifications(scheduled_for);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);
CREATE INDEX idx_notifications_related_id ON notifications(related_id);

-- Habilitar RLS (Row Level Security)
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Política para que los usuarios solo puedan ver sus propias notificaciones
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

-- Política para que los usuarios solo puedan insertar sus propias notificaciones
CREATE POLICY "Users can insert their own notifications" ON notifications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Política para que los usuarios solo puedan actualizar sus propias notificaciones
CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

-- Política para que los usuarios solo puedan eliminar sus propias notificaciones
CREATE POLICY "Users can delete their own notifications" ON notifications
    FOR DELETE USING (auth.uid() = user_id);

-- Trigger para actualizar updated_at automáticamente
CREATE TRIGGER update_notifications_updated_at
    BEFORE UPDATE ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Conceder permisos a los roles anon y authenticated
GRANT SELECT, INSERT, UPDATE, DELETE ON notifications TO authenticated;
GRANT SELECT ON notifications TO anon;

-- Función para crear notificaciones automáticas de recordatorio de hábitos
CREATE OR REPLACE FUNCTION create_habit_reminder_notification(
    p_user_id UUID,
    p_habit_id UUID,
    p_habit_title VARCHAR,
    p_scheduled_for TIMESTAMP WITH TIME ZONE
)
RETURNS UUID AS $$
DECLARE
    notification_id UUID;
BEGIN
    INSERT INTO notifications (
        user_id,
        title,
        body,
        type,
        related_id,
        scheduled_for,
        data
    ) VALUES (
        p_user_id,
        'Recordatorio de Hábito',
        'Es hora de realizar tu hábito: ' || p_habit_title,
        'habit_reminder',
        p_habit_id,
        p_scheduled_for,
        jsonb_build_object('habit_title', p_habit_title)
    ) RETURNING id INTO notification_id;
    
    RETURN notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para marcar notificaciones como leídas
CREATE OR REPLACE FUNCTION mark_notification_as_read(notification_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE notifications 
    SET is_read = true, read_at = NOW(), updated_at = NOW()
    WHERE id = notification_id AND user_id = auth.uid();
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comentarios para documentar la tabla
COMMENT ON TABLE notifications IS 'Tabla para gestionar notificaciones del usuario';
COMMENT ON COLUMN notifications.type IS 'Tipo de notificación: habit_reminder, habit_completion, system, achievement, calendar_event';
COMMENT ON COLUMN notifications.related_id IS 'ID de la entidad relacionada (hábito, evento, etc.)';
COMMENT ON COLUMN notifications.data IS 'Datos adicionales en formato JSON para la notificación';
COMMENT ON COLUMN notifications.scheduled_for IS 'Fecha y hora programada para enviar la notificación';
COMMENT ON COLUMN notifications.sent_at IS 'Fecha y hora real de envío de la notificación';