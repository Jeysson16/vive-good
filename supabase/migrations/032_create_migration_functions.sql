-- Función para verificar si una tabla existe
CREATE OR REPLACE FUNCTION check_table_exists(table_name TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = $1
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para ejecutar SQL dinámico (solo para migraciones específicas)
CREATE OR REPLACE FUNCTION execute_sql(sql TEXT)
RETURNS VOID AS $$
BEGIN
    -- Solo permitir comandos seguros para migraciones
    IF sql ~* '^(CREATE TABLE|ALTER TABLE|CREATE INDEX|CREATE POLICY|ALTER TABLE.*ENABLE ROW LEVEL SECURITY)' THEN
        EXECUTE sql;
    ELSE
        RAISE EXCEPTION 'Comando SQL no permitido: %', sql;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para verificar si una columna existe en una tabla
CREATE OR REPLACE FUNCTION check_column_exists(table_name TEXT, column_name TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = $1 
        AND column_name = $2
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para obtener información de columnas de una tabla
CREATE OR REPLACE FUNCTION get_table_columns(table_name TEXT)
RETURNS TABLE(column_name TEXT, data_type TEXT, is_nullable TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.column_name::TEXT,
        c.data_type::TEXT,
        c.is_nullable::TEXT
    FROM information_schema.columns c
    WHERE c.table_schema = 'public' 
    AND c.table_name = $1
    ORDER BY c.ordinal_position;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para crear la tabla conversations si no existe
CREATE OR REPLACE FUNCTION ensure_conversations_table()
RETURNS VOID AS $$
BEGIN
    -- Crear tabla conversations si no existe
    IF NOT check_table_exists('conversations') THEN
        CREATE TABLE conversations (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            title VARCHAR(255) DEFAULT 'Nueva conversación',
            content TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            is_active BOOLEAN DEFAULT true,
            last_message TEXT,
            last_message_at TIMESTAMP WITH TIME ZONE,
            metadata JSONB DEFAULT '{}'
        );
        
        -- Habilitar RLS
        ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
        
        -- Crear políticas RLS
        CREATE POLICY "Users can view their own conversations" ON conversations
            FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "Users can insert their own conversations" ON conversations
            FOR INSERT WITH CHECK (auth.uid() = user_id);
        CREATE POLICY "Users can update their own conversations" ON conversations
            FOR UPDATE USING (auth.uid() = user_id);
        CREATE POLICY "Users can delete their own conversations" ON conversations
            FOR DELETE USING (auth.uid() = user_id);
            
        -- Crear índices
        CREATE INDEX idx_conversations_user_id ON conversations(user_id);
        CREATE INDEX idx_conversations_created_at ON conversations(created_at);
        CREATE INDEX idx_conversations_updated_at ON conversations(updated_at);
    ELSE
        -- Asegurar que todas las columnas existan
        IF NOT check_column_exists('conversations', 'title') THEN
            ALTER TABLE conversations ADD COLUMN title VARCHAR(255) DEFAULT 'Nueva conversación';
        END IF;
        
        IF NOT check_column_exists('conversations', 'last_message') THEN
            ALTER TABLE conversations ADD COLUMN last_message TEXT;
        END IF;
        
        IF NOT check_column_exists('conversations', 'last_message_at') THEN
            ALTER TABLE conversations ADD COLUMN last_message_at TIMESTAMP WITH TIME ZONE;
        END IF;
        
        IF NOT check_column_exists('conversations', 'metadata') THEN
            ALTER TABLE conversations ADD COLUMN metadata JSONB DEFAULT '{}';
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para crear las tablas de métricas
CREATE OR REPLACE FUNCTION ensure_metrics_tables()
RETURNS VOID AS $$
BEGIN
    -- Tabla user_symptoms_knowledge
    IF NOT check_table_exists('user_symptoms_knowledge') THEN
        CREATE TABLE user_symptoms_knowledge (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
            symptom_type VARCHAR(100) NOT NULL,
            knowledge_level VARCHAR(50) NOT NULL,
            risk_factors_identified TEXT[],
            symptoms_mentioned TEXT[],
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            metadata JSONB DEFAULT '{}'
        );
        
        ALTER TABLE user_symptoms_knowledge ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "Users can view their own symptoms knowledge" ON user_symptoms_knowledge
            FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "Users can insert their own symptoms knowledge" ON user_symptoms_knowledge
            FOR INSERT WITH CHECK (auth.uid() = user_id);
            
        CREATE INDEX idx_user_symptoms_knowledge_user_id ON user_symptoms_knowledge(user_id);
        CREATE INDEX idx_user_symptoms_knowledge_conversation_id ON user_symptoms_knowledge(conversation_id);
    END IF;
    
    -- Tabla user_eating_habits
    IF NOT check_table_exists('user_eating_habits') THEN
        CREATE TABLE user_eating_habits (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
            habit_type VARCHAR(100) NOT NULL,
            risk_level VARCHAR(50) NOT NULL,
            frequency VARCHAR(50),
            habits_identified TEXT[],
            recommendations_given TEXT[],
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            metadata JSONB DEFAULT '{}'
        );
        
        ALTER TABLE user_eating_habits ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "Users can view their own eating habits" ON user_eating_habits
            FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "Users can insert their own eating habits" ON user_eating_habits
            FOR INSERT WITH CHECK (auth.uid() = user_id);
            
        CREATE INDEX idx_user_eating_habits_user_id ON user_eating_habits(user_id);
        CREATE INDEX idx_user_eating_habits_conversation_id ON user_eating_habits(conversation_id);
    END IF;
    
    -- Tabla user_healthy_habits
    IF NOT check_table_exists('user_healthy_habits') THEN
        CREATE TABLE user_healthy_habits (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
            habit_category VARCHAR(100) NOT NULL,
            adoption_status VARCHAR(50) NOT NULL,
            commitment_level VARCHAR(50),
            habits_adopted TEXT[],
            barriers_identified TEXT[],
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            metadata JSONB DEFAULT '{}'
        );
        
        ALTER TABLE user_healthy_habits ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "Users can view their own healthy habits" ON user_healthy_habits
            FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "Users can insert their own healthy habits" ON user_healthy_habits
            FOR INSERT WITH CHECK (auth.uid() = user_id);
        CREATE POLICY "Users can update their own healthy habits" ON user_healthy_habits
            FOR UPDATE USING (auth.uid() = user_id);
            
        CREATE INDEX idx_user_healthy_habits_user_id ON user_healthy_habits(user_id);
        CREATE INDEX idx_user_healthy_habits_conversation_id ON user_healthy_habits(conversation_id);
    END IF;
    
    -- Tabla user_tech_acceptance
    IF NOT check_table_exists('user_tech_acceptance') THEN
        CREATE TABLE user_tech_acceptance (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
            tool_type VARCHAR(100) NOT NULL,
            acceptance_level VARCHAR(50) NOT NULL,
            usage_frequency VARCHAR(50),
            feedback_sentiment VARCHAR(50),
            features_used TEXT[],
            suggestions_given TEXT[],
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            metadata JSONB DEFAULT '{}'
        );
        
        ALTER TABLE user_tech_acceptance ENABLE ROW LEVEL SECURITY;
        CREATE POLICY "Users can view their own tech acceptance" ON user_tech_acceptance
            FOR SELECT USING (auth.uid() = user_id);
        CREATE POLICY "Users can insert their own tech acceptance" ON user_tech_acceptance
            FOR INSERT WITH CHECK (auth.uid() = user_id);
            
        CREATE INDEX idx_user_tech_acceptance_user_id ON user_tech_acceptance(user_id);
        CREATE INDEX idx_user_tech_acceptance_conversation_id ON user_tech_acceptance(conversation_id);
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función principal para aplicar todas las migraciones
CREATE OR REPLACE FUNCTION apply_conversations_and_metrics_migration()
RETURNS VOID AS $$
BEGIN
    -- Aplicar migración de conversations
    PERFORM ensure_conversations_table();
    
    -- Aplicar migración de métricas
    PERFORM ensure_metrics_tables();
    
    -- Aplicar nuevas tablas de métricas cuantificables (033)
    PERFORM apply_metrics_tables_migration();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para verificar el estado de las migraciones
CREATE OR REPLACE FUNCTION verify_migrations_status()
RETURNS TABLE(table_name TEXT, exists BOOLEAN, columns_count INTEGER) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.table_name::TEXT,
        true as exists,
        (SELECT COUNT(*)::INTEGER 
         FROM information_schema.columns 
         WHERE table_schema = 'public' 
         AND table_name = t.table_name) as columns_count
    FROM (
        VALUES 
            ('conversations'),
            ('user_symptoms_knowledge'),
            ('user_eating_habits'),
            ('user_healthy_habits'),
            ('user_tech_acceptance'),
            ('conversation_analysis')
    ) AS t(table_name)
    WHERE check_table_exists(t.table_name);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para aplicar las nuevas tablas de métricas cuantificables (migración 033)
CREATE OR REPLACE FUNCTION apply_metrics_tables_migration()
RETURNS VOID AS $$
BEGIN
    -- Crear tabla user_symptoms_knowledge si no existe
    IF NOT check_table_exists('user_symptoms_knowledge') THEN
        EXECUTE 'CREATE TABLE user_symptoms_knowledge (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            conversation_id UUID NOT NULL,
            knowledge_level INTEGER CHECK (knowledge_level >= 1 AND knowledge_level <= 5),
            confidence_level INTEGER CHECK (confidence_level >= 1 AND confidence_level <= 5),
            symptoms_identified TEXT[],
            risk_factors_identified TEXT[],
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        )';
        
        EXECUTE 'CREATE INDEX idx_user_symptoms_knowledge_user_id ON user_symptoms_knowledge(user_id)';
        EXECUTE 'CREATE INDEX idx_user_symptoms_knowledge_conversation_id ON user_symptoms_knowledge(conversation_id)';
        EXECUTE 'CREATE INDEX idx_user_symptoms_knowledge_created_at ON user_symptoms_knowledge(created_at)';
        
        EXECUTE 'ALTER TABLE user_symptoms_knowledge ENABLE ROW LEVEL SECURITY';
        EXECUTE 'CREATE POLICY "Users can view their own symptoms knowledge" ON user_symptoms_knowledge FOR SELECT USING (auth.uid() = user_id)';
        EXECUTE 'CREATE POLICY "Users can insert their own symptoms knowledge" ON user_symptoms_knowledge FOR INSERT WITH CHECK (auth.uid() = user_id)';
        EXECUTE 'CREATE POLICY "Users can update their own symptoms knowledge" ON user_symptoms_knowledge FOR UPDATE USING (auth.uid() = user_id)';
    END IF;

    -- Crear tabla user_tech_acceptance si no existe
    IF NOT check_table_exists('user_tech_acceptance') THEN
        EXECUTE 'CREATE TABLE user_tech_acceptance (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            conversation_id UUID NOT NULL,
            acceptance_level INTEGER CHECK (acceptance_level >= 1 AND acceptance_level <= 5),
            ease_of_use INTEGER CHECK (ease_of_use >= 1 AND ease_of_use <= 5),
            usefulness INTEGER CHECK (usefulness >= 1 AND usefulness <= 5),
            intention_to_use INTEGER CHECK (intention_to_use >= 1 AND intention_to_use <= 5),
            tech_features_mentioned TEXT[],
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        )';
        
        EXECUTE 'CREATE INDEX idx_user_tech_acceptance_user_id ON user_tech_acceptance(user_id)';
        EXECUTE 'CREATE INDEX idx_user_tech_acceptance_conversation_id ON user_tech_acceptance(conversation_id)';
        EXECUTE 'CREATE INDEX idx_user_tech_acceptance_created_at ON user_tech_acceptance(created_at)';
        
        EXECUTE 'ALTER TABLE user_tech_acceptance ENABLE ROW LEVEL SECURITY';
        EXECUTE 'CREATE POLICY "Users can view their own tech acceptance" ON user_tech_acceptance FOR SELECT USING (auth.uid() = user_id)';
        EXECUTE 'CREATE POLICY "Users can insert their own tech acceptance" ON user_tech_acceptance FOR INSERT WITH CHECK (auth.uid() = user_id)';
        EXECUTE 'CREATE POLICY "Users can update their own tech acceptance" ON user_tech_acceptance FOR UPDATE USING (auth.uid() = user_id)';
    END IF;

    -- Crear tabla user_eating_habits si no existe
    IF NOT check_table_exists('user_eating_habits') THEN
        EXECUTE 'CREATE TABLE user_eating_habits (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            conversation_id UUID NOT NULL,
            risk_level INTEGER CHECK (risk_level >= 1 AND risk_level <= 5),
            habits_category TEXT CHECK (habits_category IN (''low_risk'', ''moderate_risk'', ''high_risk'')),
            risk_habits TEXT[],
            protective_habits TEXT[],
            frequency_assessment JSONB,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        )';
        
        EXECUTE 'CREATE INDEX idx_user_eating_habits_user_id ON user_eating_habits(user_id)';
        EXECUTE 'CREATE INDEX idx_user_eating_habits_conversation_id ON user_eating_habits(conversation_id)';
        EXECUTE 'CREATE INDEX idx_user_eating_habits_created_at ON user_eating_habits(created_at)';
        
        EXECUTE 'ALTER TABLE user_eating_habits ENABLE ROW LEVEL SECURITY';
        EXECUTE 'CREATE POLICY "Users can view their own eating habits" ON user_eating_habits FOR SELECT USING (auth.uid() = user_id)';
        EXECUTE 'CREATE POLICY "Users can insert their own eating habits" ON user_eating_habits FOR INSERT WITH CHECK (auth.uid() = user_id)';
        EXECUTE 'CREATE POLICY "Users can update their own eating habits" ON user_eating_habits FOR UPDATE USING (auth.uid() = user_id)';
    END IF;

    -- Crear tabla user_healthy_habits si no existe
    IF NOT check_table_exists('user_healthy_habits') THEN
        EXECUTE 'CREATE TABLE user_healthy_habits (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            conversation_id UUID NOT NULL,
            adoption_level INTEGER CHECK (adoption_level >= 1 AND adoption_level <= 5),
            habits_category TEXT CHECK (habits_category IN (''beginner'', ''intermediate'', ''advanced'')),
            healthy_habits TEXT[],
            commitment_level INTEGER CHECK (commitment_level >= 1 AND commitment_level <= 5),
            barriers_identified TEXT[],
            motivations TEXT[],
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        )';
        
        EXECUTE 'CREATE INDEX idx_user_healthy_habits_user_id ON user_healthy_habits(user_id)';
        EXECUTE 'CREATE INDEX idx_user_healthy_habits_conversation_id ON user_healthy_habits(conversation_id)';
        EXECUTE 'CREATE INDEX idx_user_healthy_habits_created_at ON user_healthy_habits(created_at)';
        
        EXECUTE 'ALTER TABLE user_healthy_habits ENABLE ROW LEVEL SECURITY';
        EXECUTE 'CREATE POLICY "Users can view their own healthy habits" ON user_healthy_habits FOR SELECT USING (auth.uid() = user_id)';
        EXECUTE 'CREATE POLICY "Users can insert their own healthy habits" ON user_healthy_habits FOR INSERT WITH CHECK (auth.uid() = user_id)';
        EXECUTE 'CREATE POLICY "Users can update their own healthy habits" ON user_healthy_habits FOR UPDATE USING (auth.uid() = user_id)';
    END IF;

    -- Crear tabla conversation_analysis si no existe
    IF NOT check_table_exists('conversation_analysis') THEN
        EXECUTE 'CREATE TABLE conversation_analysis (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            conversation_id UUID NOT NULL,
            total_messages INTEGER DEFAULT 0,
            user_engagement_score INTEGER CHECK (user_engagement_score >= 1 AND user_engagement_score <= 5),
            topics_discussed TEXT[],
            key_insights TEXT[],
            action_items TEXT[],
            sentiment_analysis JSONB,
            conversation_quality INTEGER CHECK (conversation_quality >= 1 AND conversation_quality <= 5),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        )';
        
        EXECUTE 'CREATE INDEX idx_conversation_analysis_user_id ON conversation_analysis(user_id)';
        EXECUTE 'CREATE INDEX idx_conversation_analysis_conversation_id ON conversation_analysis(conversation_id)';
        EXECUTE 'CREATE INDEX idx_conversation_analysis_created_at ON conversation_analysis(created_at)';
        
        EXECUTE 'ALTER TABLE conversation_analysis ENABLE ROW LEVEL SECURITY';
        EXECUTE 'CREATE POLICY "Users can view their own conversation analysis" ON conversation_analysis FOR SELECT USING (auth.uid() = user_id)';
        EXECUTE 'CREATE POLICY "Users can insert their own conversation analysis" ON conversation_analysis FOR INSERT WITH CHECK (auth.uid() = user_id)';
        EXECUTE 'CREATE POLICY "Users can update their own conversation analysis" ON conversation_analysis FOR UPDATE USING (auth.uid() = user_id)';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;