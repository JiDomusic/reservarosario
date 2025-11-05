-- LIMPIAR Y REPOBLAR TABLAS - VERSIÓN CORREGIDA
-- Ejecutar esto en Supabase SQL Editor

-- 1. Limpiar todas las tablas en orden correcto
TRUNCATE restaurant_analytics CASCADE;
TRUNCATE restaurant_reviews CASCADE;
TRUNCATE restaurant_reservations CASCADE;
TRUNCATE restaurant_schedules CASCADE;
TRUNCATE restaurant_tables CASCADE;
TRUNCATE restaurants CASCADE;

-- 2. Insertar 10 restaurantes demo
INSERT INTO restaurants (name, description, email, total_tables, phone, address) VALUES
('AMELIE PETIT CAFE', 'Café francés con ambiente íntimo y deliciosa repostería artesanal', 'admin@ameliepetitcafe.com', 12, '+54 341 456-7890', 'Av. Pellegrini 1234, Rosario'),
('LA COCINA DE MAMA', 'Comida casera argentina con el sabor de la abuela', 'admin@lacocinademama.com', 15, '+54 341 456-7891', 'San Martín 567, Rosario'),
('PIZZA CORNER', 'Las mejores pizzas artesanales de la ciudad', 'admin@pizzacorner.com', 20, '+54 341 456-7892', 'Córdoba 890, Rosario'),
('SUSHI ZEN', 'Auténtica cocina japonesa y sushi fresco', 'admin@sushizen.com', 18, '+54 341 456-7893', 'Montevideo 345, Rosario'),
('PARRILLA DON CARLOS', 'Carnes premium y parrilla tradicional argentina', 'admin@parrilladoncarlos.com', 25, '+54 341 456-7894', 'Rioja 678, Rosario'),
('VERDE NATURAL', 'Cocina vegetariana y vegana saludable', 'admin@verdenatural.com', 14, '+54 341 456-7895', 'Entre Ríos 234, Rosario'),
('MARISCOS DEL PUERTO', 'Pescados y mariscos frescos del día', 'admin@mariscospuerto.com', 16, '+54 341 456-7896', 'Av. Belgrano 789, Rosario'),
('TACO LOCO', 'Comida mexicana auténtica y picante', 'admin@tacoloco.com', 22, '+54 341 456-7897', 'Mitre 456, Rosario'),
('PASTA BELLA', 'Pastas artesanales y cocina italiana tradicional', 'admin@pastabella.com', 19, '+54 341 456-7898', 'Urquiza 123, Rosario'),
('BRUNCH CLUB', 'Desayunos gourmet y brunch todo el día', 'admin@brunchclub.com', 13, '+54 341 456-7899', 'Sarmiento 321, Rosario');

-- 3. Trigger automático para conectar nuevos usuarios
CREATE OR REPLACE FUNCTION handle_new_restaurant_user()
RETURNS trigger AS $$
BEGIN
  -- Conectar automáticamente nuevos usuarios auth con tabla restaurants
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