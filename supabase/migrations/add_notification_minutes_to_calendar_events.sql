-- Add notification_minutes column to calendar_events table
-- This column is used by the application code instead of reminder_minutes

ALTER TABLE calendar_events 
ADD COLUMN notification_minutes INTEGER DEFAULT 15;

COMMENT ON COLUMN calendar_events.notification_minutes IS 'Minutos antes del evento para enviar notificación (usado por la aplicación)';

-- Grant permissions to anon and authenticated roles
GRANT SELECT, INSERT, UPDATE ON calendar_events TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON calendar_events TO authenticated;