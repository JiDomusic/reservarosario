-- ============================================
-- SCRIPT PARA CREAR USUARIOS DEMO EN SUPABASE AUTH
-- ============================================

-- NOTA: Este script debe ejecutarse después de crear los usuarios manualmente 
-- en Supabase Auth, para actualizar la tabla restaurants con los auth_user_id

-- Ejemplo de cómo actualizar los restaurantes demo con usuarios reales:

-- 1. Crear estos usuarios manualmente en Supabase Auth Dashboard:
--    - admin@ameliepetitcafe.com (password: 123456)
--    - admin@lacocinademama.com (password: 123456)
--    - admin@pizzacorner.com (password: 123456)
--    - admin@sushizen.com (password: 123456)
--    - admin@parrilladoncarlos.com (password: 123456)

-- 2. Una vez creados, obtener sus UUIDs y actualizar la tabla:

-- EJEMPLO (reemplazar los UUIDs con los reales):
/*
UPDATE restaurants 
SET auth_user_id = '12345678-1234-1234-1234-123456789abc'
WHERE email = 'admin@ameliepetitcafe.com';

UPDATE restaurants 
SET auth_user_id = '12345678-1234-1234-1234-123456789def'
WHERE email = 'admin@lacocinademama.com';

UPDATE restaurants 
SET auth_user_id = '12345678-1234-1234-1234-123456789ghi'
WHERE email = 'admin@pizzacorner.com';

UPDATE restaurants 
SET auth_user_id = '12345678-1234-1234-1234-123456789jkl'
WHERE email = 'admin@sushizen.com';

UPDATE restaurants 
SET auth_user_id = '12345678-1234-1234-1234-123456789mno'
WHERE email = 'admin@parrilladoncarlos.com';
*/

-- ============================================
-- ALTERNATIVA: TRIGGER AUTOMÁTICO
-- ============================================

-- Este trigger automáticamente conecta nuevos usuarios de auth con la tabla restaurants
CREATE OR REPLACE FUNCTION handle_new_restaurant_user()
RETURNS trigger AS $$
BEGIN
  -- Buscar si existe un restaurante con este email
  UPDATE restaurants 
  SET auth_user_id = NEW.id
  WHERE email = NEW.email 
  AND auth_user_id IS NULL;
  
  RETURN NEW;
END;
$$ language plpgsql security definer;

-- Crear el trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_restaurant_user();

-- ============================================
-- CONSULTAS ÚTILES PARA DEBUG
-- ============================================

-- Ver usuarios de auth creados
-- SELECT id, email, created_at FROM auth.users ORDER BY created_at DESC;

-- Ver restaurantes sin auth_user_id
-- SELECT name, email, auth_user_id FROM restaurants WHERE auth_user_id IS NULL;

-- Ver restaurantes conectados con auth
-- SELECT r.name, r.email, r.auth_user_id, u.email as auth_email 
-- FROM restaurants r 
-- LEFT JOIN auth.users u ON r.auth_user_id = u.id;