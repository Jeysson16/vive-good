-- Crear bucket de Storage para fotos de perfil
-- Configuración básica de Supabase Storage para profile-images
-- Nota: Las políticas RLS deben configurarse desde el dashboard de Supabase

-- 1. Crear el bucket 'profile-images' si no existe
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile-images',
  'profile-images', 
  true,
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
ON CONFLICT (id) DO NOTHING;

-- 2. Verificar que el bucket fue creado correctamente
SELECT 
  'Bucket profile-images configurado correctamente' as status,
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets 
WHERE id = 'profile-images';

-- Nota: Para configurar las políticas RLS de Storage, usar el dashboard de Supabase:
-- 1. Ir a Storage > Policies
-- 2. Crear políticas para el bucket 'profile-images':
--    - INSERT: Users can upload their own profile images
--    - SELECT: Public can view profile images  
--    - UPDATE: Users can update their own profile images
--    - DELETE: Users can delete their own profile images

SELECT 'Configuración de Storage completada. Configurar políticas RLS desde el dashboard.' as info;