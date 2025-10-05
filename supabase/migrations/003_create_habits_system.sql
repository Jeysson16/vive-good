-- Crear tabla de categorías de hábitos
CREATE TABLE categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    color VARCHAR(7) NOT NULL DEFAULT '#4CAF50', -- Hex color
    icon VARCHAR(50) NOT NULL DEFAULT 'star',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

-- Crear tabla de hábitos (repositorio de todos los hábitos saludables)
CREATE TABLE habits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

-- Crear tabla de relación usuario-hábito (para pantalla Main)
CREATE TABLE user_habits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    habit_id UUID REFERENCES habits(id) ON DELETE CASCADE,
    frequency VARCHAR(20) NOT NULL DEFAULT 'daily', -- daily, weekly, monthly, custom
    frequency_details JSONB, -- días de la semana, veces por día, etc.
    scheduled_time TIME, -- hora del día para el hábito
    notifications_enabled BOOLEAN DEFAULT true,
    notification_time TIME, -- cuándo enviar notificación
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    start_time TIME,
    end_date DATE, -- opcional - cuándo se completó/detuvo
    end_time TIME, -- opcional - hora cuando terminó
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, habit_id) -- Un usuario no puede tener el mismo hábito duplicado activo
);

-- Crear tabla de registros de hábitos del usuario (seguimiento diario)
CREATE TABLE user_habit_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_habit_id UUID REFERENCES user_habits(id) ON DELETE CASCADE,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- completed, skipped, pending
    notes TEXT, -- notas opcionales del usuario
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Habilitar RLS (Row Level Security) en todas las tablas
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_habit_logs ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para categories (solo administradores pueden crear/editar)
CREATE POLICY "Categories are viewable by everyone" ON categories
    FOR SELECT USING (true);

CREATE POLICY "Only admins can insert categories" ON categories
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Only creators can update categories" ON categories
    FOR UPDATE USING (auth.uid() = created_by);

-- Políticas RLS para habits (solo administradores pueden crear/editar)
CREATE POLICY "Habits are viewable by everyone" ON habits
    FOR SELECT USING (true);

CREATE POLICY "Only admins can insert habits" ON habits
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Only creators can update habits" ON habits
    FOR UPDATE USING (auth.uid() = created_by);

-- Políticas RLS para user_habits (usuarios solo pueden ver/editar sus propios hábitos)
CREATE POLICY "Users can view their own habits" ON user_habits
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own habits" ON user_habits
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own habits" ON user_habits
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own habits" ON user_habits
    FOR DELETE USING (auth.uid() = user_id);

-- Políticas RLS para user_habit_logs (usuarios solo pueden ver/editar sus propios registros)
CREATE POLICY "Users can view their own habit logs" ON user_habit_logs
    FOR SELECT USING (
        auth.uid() = (SELECT user_id FROM user_habits WHERE id = user_habit_id)
    );

CREATE POLICY "Users can insert their own habit logs" ON user_habit_logs
    FOR INSERT WITH CHECK (
        auth.uid() = (SELECT user_id FROM user_habits WHERE id = user_habit_id)
    );

CREATE POLICY "Users can update their own habit logs" ON user_habit_logs
    FOR UPDATE USING (
        auth.uid() = (SELECT user_id FROM user_habits WHERE id = user_habit_id)
    );

CREATE POLICY "Users can delete their own habit logs" ON user_habit_logs
    FOR DELETE USING (
        auth.uid() = (SELECT user_id FROM user_habits WHERE id = user_habit_id)
    );

-- Crear índices para optimizar el rendimiento
CREATE INDEX idx_habits_category_id ON habits(category_id);
CREATE INDEX idx_user_habits_user_id ON user_habits(user_id);
CREATE INDEX idx_user_habits_habit_id ON user_habits(habit_id);
CREATE INDEX idx_user_habits_active ON user_habits(is_active);
CREATE INDEX idx_user_habit_logs_user_habit_id ON user_habit_logs(user_habit_id);
CREATE INDEX idx_user_habit_logs_status ON user_habit_logs(status);
CREATE INDEX idx_user_habit_logs_completed_at ON user_habit_logs(completed_at);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para actualizar updated_at
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_habits_updated_at BEFORE UPDATE ON habits
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_habits_updated_at BEFORE UPDATE ON user_habits
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insertar categorías de ejemplo
INSERT INTO categories (name, description, color, icon) VALUES
('Alimentación', 'Hábitos relacionados con una alimentación saludable', '#4CAF50', 'utensils'),
('Actividad Física', 'Ejercicios y actividades físicas', '#2196F3', 'activity'),
('Sueño', 'Hábitos para mejorar la calidad del sueño', '#9C27B0', 'moon'),
('Hidratación', 'Consumo adecuado de líquidos', '#00BCD4', 'droplet'),
('Bienestar Mental', 'Actividades para la salud mental', '#FF9800', 'brain'),
('Productividad', 'Hábitos para mejorar la productividad', '#795548', 'target');

-- Insertar hábitos de ejemplo
INSERT INTO habits (name, description, category_id) VALUES
-- Alimentación
('Beber 250 ml de agua', 'Consumir un vaso de agua para mantenerse hidratado', (SELECT id FROM categories WHERE name = 'Hidratación')),
('Comer frutas en la mañana', 'Incluir frutas frescas en el desayuno', (SELECT id FROM categories WHERE name = 'Alimentación')),
('Almorzar a las 12 pm', 'Mantener horarios regulares de comida', (SELECT id FROM categories WHERE name = 'Alimentación')),
-- Actividad Física
('Caminar 30 minutos', 'Realizar una caminata diaria de 30 minutos', (SELECT id FROM categories WHERE name = 'Actividad Física')),
('Hacer ejercicios de estiramiento', 'Realizar rutina de estiramiento matutino', (SELECT id FROM categories WHERE name = 'Actividad Física')),
-- Sueño
('Dormir 8 horas', 'Mantener un horario de sueño saludable', (SELECT id FROM categories WHERE name = 'Sueño')),
('Evitar pantallas antes de dormir', 'No usar dispositivos electrónicos 1 hora antes de dormir', (SELECT id FROM categories WHERE name = 'Sueño')),
-- Bienestar Mental
('Meditar 10 minutos', 'Práctica diaria de meditación', (SELECT id FROM categories WHERE name = 'Bienestar Mental')),
('Escribir en diario', 'Reflexionar y escribir pensamientos del día', (SELECT id FROM categories WHERE name = 'Bienestar Mental')),
-- Productividad
('Leer 20 páginas', 'Lectura diaria para el crecimiento personal', (SELECT id FROM categories WHERE name = 'Productividad')),
('Planificar el día', 'Organizar tareas y objetivos diarios', (SELECT id FROM categories WHERE name = 'Productividad'));

-- Otorgar permisos a los roles anon y authenticated
GRANT SELECT ON categories TO anon, authenticated;
GRANT SELECT ON habits TO anon, authenticated;
GRANT ALL ON user_habits TO authenticated;
GRANT ALL ON user_habit_logs TO authenticated;
GRANT INSERT ON categories TO authenticated;
GRANT INSERT ON habits TO authenticated;

-- Otorgar permisos en las secuencias
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO anon;