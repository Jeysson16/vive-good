-- Create user_progress table for tracking user progress metrics
CREATE TABLE IF NOT EXISTS public.user_progress (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    user_name VARCHAR(255) NOT NULL,
    user_profile_image TEXT DEFAULT '',
    weekly_completed_habits INTEGER DEFAULT 0,
    suggested_habits INTEGER DEFAULT 0,
    pending_activities INTEGER DEFAULT 0,
    new_habits INTEGER DEFAULT 0,
    weekly_progress_percentage DECIMAL(5,2) DEFAULT 0.0,
    accepted_nutrition_suggestions INTEGER DEFAULT 0,
    motivational_message TEXT DEFAULT 'Keep going! You''re doing great!',
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.user_progress ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Users can only see their own progress
CREATE POLICY "Users can view own progress" ON public.user_progress
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own progress
CREATE POLICY "Users can insert own progress" ON public.user_progress
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own progress
CREATE POLICY "Users can update own progress" ON public.user_progress
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own progress
CREATE POLICY "Users can delete own progress" ON public.user_progress
    FOR DELETE USING (auth.uid() = user_id);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_user_progress_user_id ON public.user_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_last_updated ON public.user_progress(last_updated);

-- Create trigger to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_progress_updated_at
    BEFORE UPDATE ON public.user_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions to authenticated users
GRANT ALL PRIVILEGES ON public.user_progress TO authenticated;
GRANT SELECT ON public.user_progress TO anon;

-- Function to calculate user progress based on user_habits and user_habit_logs
CREATE OR REPLACE FUNCTION calculate_user_progress(p_user_id UUID)
RETURNS TABLE (
    weekly_completed_habits INTEGER,
    suggested_habits INTEGER,
    pending_activities INTEGER,
    new_habits INTEGER,
    weekly_progress_percentage DECIMAL(5,2)
) AS $$
BEGIN
    RETURN QUERY
    WITH habit_stats AS (
        SELECT 
            uh.id as user_habit_id,
            uh.created_at,
            -- Check if completed this week based on logs
            CASE WHEN EXISTS(
                SELECT 1 FROM user_habit_logs uhl 
                WHERE uhl.user_habit_id = uh.id 
                AND uhl.status = 'completed'
                AND uhl.completed_at >= NOW() - INTERVAL '7 days'
            ) THEN 1 ELSE 0 END as completed_this_week,
            -- Check if it's a suggested habit (public habits)
            CASE WHEN uh.is_public = true THEN 1 ELSE 0 END as is_suggested,
            -- Check if it's pending (active but not completed today)
            CASE WHEN uh.is_active = true AND NOT EXISTS(
                SELECT 1 FROM user_habit_logs uhl 
                WHERE uhl.user_habit_id = uh.id 
                AND uhl.status = 'completed'
                AND DATE(uhl.completed_at) = CURRENT_DATE
            ) THEN 1 ELSE 0 END as is_pending
        FROM public.user_habits uh
        WHERE uh.user_id = p_user_id AND uh.is_active = true
    )
    SELECT 
        COALESCE(SUM(hs.completed_this_week)::INTEGER, 0) as weekly_completed_habits,
        COALESCE(SUM(hs.is_suggested)::INTEGER, 0) as suggested_habits,
        COALESCE(SUM(hs.is_pending)::INTEGER, 0) as pending_activities,
        COALESCE(COUNT(CASE WHEN hs.created_at >= NOW() - INTERVAL '7 days' THEN 1 END)::INTEGER, 0) as new_habits,
        CASE 
            WHEN COUNT(*) > 0 THEN 
                ROUND((SUM(hs.completed_this_week)::DECIMAL / COUNT(*)::DECIMAL) * 100, 2)
            ELSE 0.0
        END as weekly_progress_percentage
    FROM habit_stats hs;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to upsert user progress based on calculated data
CREATE OR REPLACE FUNCTION upsert_user_progress(p_user_id UUID, p_user_name VARCHAR(255) DEFAULT NULL, p_user_profile_image TEXT DEFAULT '')
RETURNS VOID AS $$
DECLARE
    progress_data RECORD;
BEGIN
    -- Calculate progress data
    SELECT * INTO progress_data FROM calculate_user_progress(p_user_id);
    
    -- Upsert user progress
    INSERT INTO public.user_progress (
        user_id,
        user_name,
        user_profile_image,
        weekly_completed_habits,
        suggested_habits,
        pending_activities,
        new_habits,
        weekly_progress_percentage,
        accepted_nutrition_suggestions,
        motivational_message
    ) VALUES (
        p_user_id,
        COALESCE(p_user_name, 'Usuario'),
        COALESCE(p_user_profile_image, ''),
        progress_data.weekly_completed_habits,
        progress_data.suggested_habits,
        progress_data.pending_activities,
        progress_data.new_habits,
        progress_data.weekly_progress_percentage,
        0, -- accepted_nutrition_suggestions
        CASE 
            WHEN progress_data.weekly_progress_percentage >= 80 THEN '¡Excelente progreso! Sigue así.'
            WHEN progress_data.weekly_progress_percentage >= 50 THEN '¡Buen trabajo! Estás en el camino correcto.'
            ELSE '¡Sigue adelante! Cada paso cuenta.'
        END
    )
    ON CONFLICT (user_id) DO UPDATE SET
        user_name = EXCLUDED.user_name,
        user_profile_image = EXCLUDED.user_profile_image,
        weekly_completed_habits = EXCLUDED.weekly_completed_habits,
        suggested_habits = EXCLUDED.suggested_habits,
        pending_activities = EXCLUDED.pending_activities,
        new_habits = EXCLUDED.new_habits,
        weekly_progress_percentage = EXCLUDED.weekly_progress_percentage,
        accepted_nutrition_suggestions = EXCLUDED.accepted_nutrition_suggestions,
        motivational_message = EXCLUDED.motivational_message,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION calculate_user_progress(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION upsert_user_progress(UUID, VARCHAR(255), TEXT) TO authenticated;