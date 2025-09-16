-- Create calendar_events table
CREATE TABLE calendar_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    start_time TIME,
    end_date DATE,
    end_time TIME,
    event_type VARCHAR(50) DEFAULT 'activity', -- 'activity', 'habit', 'reminder'
    category_id UUID REFERENCES categories(id),
    habit_id UUID REFERENCES habits(id),
    is_all_day BOOLEAN DEFAULT false,
    is_recurring BOOLEAN DEFAULT false,
    recurrence_pattern VARCHAR(50), -- 'daily', 'weekly', 'monthly', 'yearly'
    recurrence_end_date DATE,
    location VARCHAR(255),
    priority VARCHAR(20) DEFAULT 'medium', -- 'low', 'medium', 'high'
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'completed', 'cancelled'
    reminder_minutes INTEGER DEFAULT 15,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create habit_schedules table
CREATE TABLE habit_schedules (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    habit_id UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
    scheduled_date DATE NOT NULL,
    scheduled_time TIME,
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMP WITH TIME ZONE,
    reminder_enabled BOOLEAN DEFAULT true,
    reminder_minutes INTEGER DEFAULT 15,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, habit_id, scheduled_date)
);

-- Create notifications table
CREATE TABLE notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'habit_reminder', 'event_reminder', 'achievement'
    reference_id UUID, -- ID of the related habit, event, etc.
    reference_type VARCHAR(50), -- 'habit', 'event', 'achievement'
    scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE,
    is_read BOOLEAN DEFAULT false,
    is_sent BOOLEAN DEFAULT false,
    data JSONB, -- Additional data for the notification
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_activities table
CREATE TABLE user_activities (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    activity_name VARCHAR(255) NOT NULL,
    description TEXT,
    category_id UUID REFERENCES categories(id),
    duration_minutes INTEGER,
    calories_burned INTEGER,
    activity_date DATE NOT NULL,
    start_time TIME,
    end_time TIME,
    location VARCHAR(255),
    notes TEXT,
    mood_rating INTEGER CHECK (mood_rating >= 1 AND mood_rating <= 5),
    energy_level INTEGER CHECK (energy_level >= 1 AND energy_level <= 5),
    tags TEXT[], -- Array of tags
    is_favorite BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_calendar_events_user_id ON calendar_events(user_id);
CREATE INDEX idx_calendar_events_start_date ON calendar_events(start_date);
CREATE INDEX idx_calendar_events_type ON calendar_events(event_type);
CREATE INDEX idx_calendar_events_status ON calendar_events(status);

CREATE INDEX idx_habit_schedules_user_id ON habit_schedules(user_id);
CREATE INDEX idx_habit_schedules_habit_id ON habit_schedules(habit_id);
CREATE INDEX idx_habit_schedules_date ON habit_schedules(scheduled_date);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_scheduled_at ON notifications(scheduled_at);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_is_sent ON notifications(is_sent);

CREATE INDEX idx_user_activities_user_id ON user_activities(user_id);
CREATE INDEX idx_user_activities_date ON user_activities(activity_date);
CREATE INDEX idx_user_activities_category ON user_activities(category_id);

-- Enable Row Level Security (RLS)
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE habit_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_activities ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Calendar Events policies
CREATE POLICY "Users can view their own calendar events" ON calendar_events
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own calendar events" ON calendar_events
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own calendar events" ON calendar_events
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own calendar events" ON calendar_events
    FOR DELETE USING (auth.uid() = user_id);

-- Habit Schedules policies
CREATE POLICY "Users can view their own habit schedules" ON habit_schedules
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own habit schedules" ON habit_schedules
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own habit schedules" ON habit_schedules
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own habit schedules" ON habit_schedules
    FOR DELETE USING (auth.uid() = user_id);

-- Notifications policies
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own notifications" ON notifications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own notifications" ON notifications
    FOR DELETE USING (auth.uid() = user_id);

-- User Activities policies
CREATE POLICY "Users can view their own activities" ON user_activities
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own activities" ON user_activities
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own activities" ON user_activities
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own activities" ON user_activities
    FOR DELETE USING (auth.uid() = user_id);

-- Grant permissions to authenticated users
GRANT ALL PRIVILEGES ON calendar_events TO authenticated;
GRANT ALL PRIVILEGES ON habit_schedules TO authenticated;
GRANT ALL PRIVILEGES ON notifications TO authenticated;
GRANT ALL PRIVILEGES ON user_activities TO authenticated;

-- Grant basic read access to anon role (for public events if needed)
GRANT SELECT ON calendar_events TO anon;
GRANT SELECT ON user_activities TO anon;

-- Create functions for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for automatic timestamp updates
CREATE TRIGGER update_calendar_events_updated_at BEFORE UPDATE ON calendar_events
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_habit_schedules_updated_at BEFORE UPDATE ON habit_schedules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notifications_updated_at BEFORE UPDATE ON notifications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_activities_updated_at BEFORE UPDATE ON user_activities
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert some sample data for testing
INSERT INTO calendar_events (user_id, title, description, start_date, start_time, event_type, priority)
SELECT 
    auth.uid(),
    'Ejercicio matutino',
    'Rutina de ejercicios de 30 minutos',
    CURRENT_DATE + INTERVAL '1 day',
    '07:00:00',
    'activity',
    'high'
WHERE auth.uid() IS NOT NULL;

INSERT INTO calendar_events (user_id, title, description, start_date, start_time, event_type, priority)
SELECT 
    auth.uid(),
    'Meditación',
    'Sesión de meditación de 15 minutos',
    CURRENT_DATE,
    '20:00:00',
    'activity',
    'medium'
WHERE auth.uid() IS NOT NULL;