-- Create risk_eating_habits table
CREATE TABLE IF NOT EXISTS public.risk_eating_habits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    habits JSONB NOT NULL DEFAULT '[]'::jsonb,
    total_risk INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.risk_eating_habits ENABLE ROW LEVEL SECURITY;

-- Create policies for RLS
CREATE POLICY "Users can view their own risk eating habits" ON public.risk_eating_habits
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own risk eating habits" ON public.risk_eating_habits
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own risk eating habits" ON public.risk_eating_habits
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own risk eating habits" ON public.risk_eating_habits
    FOR DELETE USING (auth.uid() = user_id);

-- Grant permissions to anon and authenticated roles
GRANT SELECT ON public.risk_eating_habits TO anon;
GRANT ALL PRIVILEGES ON public.risk_eating_habits TO authenticated;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_risk_eating_habits_user_id ON public.risk_eating_habits(user_id);
CREATE INDEX IF NOT EXISTS idx_risk_eating_habits_created_at ON public.risk_eating_habits(created_at);

-- Create trigger to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_risk_eating_habits_updated_at 
    BEFORE UPDATE ON public.risk_eating_habits 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();