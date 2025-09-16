-- Fix infinite recursion in user_roles policies
-- The problem: policies reference the same table they're protecting

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Admins can view all user roles" ON user_roles;
DROP POLICY IF EXISTS "Admins can manage user roles" ON user_roles;
DROP POLICY IF EXISTS "Users can view own roles" ON user_roles;

-- Create simple, non-recursive policies for user_roles
-- Allow users to view their own roles
CREATE POLICY "Users can view own roles" ON user_roles
    FOR SELECT USING (auth.uid() = user_id);

-- Allow authenticated users to insert their own role assignments
-- This is needed for registration process
CREATE POLICY "Users can insert own roles" ON user_roles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- For admin operations, we'll handle them through service role or functions
-- instead of RLS policies to avoid recursion

-- Grant basic permissions to authenticated role for user_roles
GRANT SELECT, INSERT ON user_roles TO authenticated;

-- Create a simple function to assign default user role
-- This will be used during registration without triggering RLS recursion
CREATE OR REPLACE FUNCTION public.assign_user_role(user_uuid UUID, role_name TEXT DEFAULT 'user')
RETURNS BOOLEAN AS $$
DECLARE
    target_role_id UUID;
BEGIN
    -- Get the role ID
    SELECT id INTO target_role_id FROM roles WHERE name = role_name;
    
    IF target_role_id IS NULL THEN
        RAISE EXCEPTION 'Role % not found', role_name;
    END IF;
    
    -- Insert the user role assignment
    INSERT INTO user_roles (user_id, role_id)
    VALUES (user_uuid, target_role_id)
    ON CONFLICT (user_id, role_id) DO NOTHING;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update the handle_new_user function to use the new assign_user_role function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert profile
    INSERT INTO public.profiles (id, first_name, last_name, email)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'first_name', ''),
        COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
        NEW.email
    );
    
    -- Assign default user role using the new function
    PERFORM public.assign_user_role(NEW.id, 'user');
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the new function
GRANT EXECUTE ON FUNCTION public.assign_user_role(UUID, TEXT) TO authenticated;