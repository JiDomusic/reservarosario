-- ============================================
-- SCHEMA LIMPIO PARA SISTEMA MULTI-RESTAURANTE
-- COMPATIBLE CON SUPABASE AUTH
-- NO TOCA NADA DE SODITA - SOLO AGREGA TABLAS NUEVAS
-- ============================================

-- Primero, limpiar tablas existentes si existen
DROP TABLE IF EXISTS restaurant_analytics CASCADE;
DROP TABLE IF EXISTS restaurant_reviews CASCADE;
DROP TABLE IF EXISTS restaurant_reservations CASCADE;
DROP TABLE IF EXISTS restaurant_schedules CASCADE;
DROP TABLE IF EXISTS restaurant_tables CASCADE;
DROP TABLE IF EXISTS restaurants CASCADE;

-- Crear tabla principal de restaurantes
CREATE TABLE restaurants (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    logo_url TEXT,
    cover_image_url TEXT,
    address TEXT,
    phone VARCHAR(50),
    whatsapp VARCHAR(50),
    email VARCHAR(255) UNIQUE NOT NULL,
    auth_user_id UUID UNIQUE, -- Referencia a auth.users de Supabase
    total_tables INTEGER DEFAULT 10,
    primary_color VARCHAR(7) DEFAULT '#F86704',
    secondary_color VARCHAR(7) DEFAULT '#10B981',
    is_active BOOLEAN DEFAULT true,
    is_open BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Mesas por restaurante
CREATE TABLE restaurant_tables (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    table_number INTEGER NOT NULL,
    capacity INTEGER NOT NULL,
    location VARCHAR(255),
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(restaurant_id, table_number)
);

-- Reservas por restaurante
CREATE TABLE restaurant_reservations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    table_id UUID REFERENCES restaurant_tables(id),
    customer_name VARCHAR(255) NOT NULL,
    customer_phone VARCHAR(50),
    customer_email VARCHAR(255),
    party_size INTEGER NOT NULL,
    reservation_date DATE NOT NULL,
    reservation_time TIME NOT NULL,
    notes TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Reviews por restaurante
CREATE TABLE restaurant_reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    customer_name VARCHAR(255),
    customer_email VARCHAR(255),
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Horarios por restaurante
CREATE TABLE restaurant_schedules (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
    open_time TIME NOT NULL,
    close_time TIME NOT NULL,
    is_closed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(restaurant_id, day_of_week)
);

-- Analytics por restaurante
CREATE TABLE restaurant_analytics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    total_reservations INTEGER DEFAULT 0,
    completed_reservations INTEGER DEFAULT 0,
    cancelled_reservations INTEGER DEFAULT 0,
    no_show_reservations INTEGER DEFAULT 0,
    total_revenue DECIMAL(10,2) DEFAULT 0,
    average_party_size DECIMAL(3,1) DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(restaurant_id, date)
);

-- Habilitar Row Level Security
ALTER TABLE restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE restaurant_tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE restaurant_reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE restaurant_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE restaurant_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE restaurant_analytics ENABLE ROW LEVEL SECURITY;

-- ============================================
-- INSERTAR 10 RESTAURANTES DEMO
-- ============================================

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

-- ============================================
-- CREAR MESAS PARA CADA RESTAURANTE
-- ============================================

DO $$
DECLARE
    restaurant_record RECORD;
    i INTEGER;
BEGIN
    FOR restaurant_record IN SELECT id, total_tables FROM restaurants LOOP
        FOR i IN 1..restaurant_record.total_tables LOOP
            INSERT INTO restaurant_tables (restaurant_id, table_number, capacity, location)
            VALUES (
                restaurant_record.id,
                i,
                CASE 
                    WHEN i <= restaurant_record.total_tables * 0.4 THEN 2  -- 40% mesas para 2
                    WHEN i <= restaurant_record.total_tables * 0.7 THEN 4  -- 30% mesas para 4
                    ELSE 6  -- 30% mesas para 6
                END,
                CASE 
                    WHEN i <= restaurant_record.total_tables * 0.5 THEN 'Interior'
                    ELSE 'Terraza'
                END
            );
        END LOOP;
    END LOOP;
END $$;

-- ============================================
-- CREAR HORARIOS PARA CADA RESTAURANTE
-- ============================================

DO $$
DECLARE
    restaurant_record RECORD;
    i INTEGER;
BEGIN
    FOR restaurant_record IN SELECT id FROM restaurants LOOP
        FOR i IN 0..6 LOOP -- 0=Domingo, 6=Sábado
            INSERT INTO restaurant_schedules (restaurant_id, day_of_week, open_time, close_time, is_closed)
            VALUES (
                restaurant_record.id,
                i,
                CASE WHEN i = 0 THEN '10:00:00'::TIME ELSE '08:00:00'::TIME END,
                CASE WHEN i IN (0,6) THEN '00:00:00'::TIME ELSE '23:00:00'::TIME END,
                false
            );
        END LOOP;
    END LOOP;
END $$;

-- ============================================
-- POLÍTICAS RLS (Row Level Security)
-- ============================================

-- Política para restaurants: solo el propietario puede ver/editar sus datos
CREATE POLICY "Restaurant owners can manage their own data" ON restaurants
    FOR ALL USING (auth_user_id = auth.uid());

-- Política para restaurant_tables: solo el propietario del restaurante puede gestionarlas
CREATE POLICY "Restaurant owners can manage their tables" ON restaurant_tables
    FOR ALL USING (
        restaurant_id IN (
            SELECT id FROM restaurants WHERE auth_user_id = auth.uid()
        )
    );

-- Política para restaurant_reservations: solo el propietario del restaurante puede ver sus reservas
CREATE POLICY "Restaurant owners can manage their reservations" ON restaurant_reservations
    FOR ALL USING (
        restaurant_id IN (
            SELECT id FROM restaurants WHERE auth_user_id = auth.uid()
        )
    );

-- Política para restaurant_reviews: solo el propietario del restaurante puede ver sus reviews
CREATE POLICY "Restaurant owners can view their reviews" ON restaurant_reviews
    FOR SELECT USING (
        restaurant_id IN (
            SELECT id FROM restaurants WHERE auth_user_id = auth.uid()
        )
    );

-- Política para restaurant_analytics: solo el propietario del restaurante puede ver sus analytics
CREATE POLICY "Restaurant owners can view their analytics" ON restaurant_analytics
    FOR ALL USING (
        restaurant_id IN (
            SELECT id FROM restaurants WHERE auth_user_id = auth.uid()
        )
    );

-- Políticas públicas para usuarios no autenticados
CREATE POLICY "Public can view active restaurants" ON restaurants
    FOR SELECT USING (is_active = true);

CREATE POLICY "Public can view available tables" ON restaurant_tables
    FOR SELECT USING (
        is_available = true AND 
        restaurant_id IN (SELECT id FROM restaurants WHERE is_active = true)
    );

CREATE POLICY "Public can create reservations" ON restaurant_reservations
    FOR INSERT WITH CHECK (
        restaurant_id IN (SELECT id FROM restaurants WHERE is_active = true AND is_open = true)
    );

-- ============================================
-- ÍNDICES PARA PERFORMANCE
-- ============================================

CREATE INDEX IF NOT EXISTS idx_restaurants_email ON restaurants(email);
CREATE INDEX IF NOT EXISTS idx_restaurants_auth_user_id ON restaurants(auth_user_id);
CREATE INDEX IF NOT EXISTS idx_restaurants_active ON restaurants(is_active);
CREATE INDEX IF NOT EXISTS idx_restaurant_tables_restaurant_id ON restaurant_tables(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_restaurant_reservations_restaurant_id ON restaurant_reservations(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_restaurant_reservations_date ON restaurant_reservations(reservation_date);
CREATE INDEX IF NOT EXISTS idx_restaurant_reservations_status ON restaurant_reservations(status);
CREATE INDEX IF NOT EXISTS idx_restaurant_reviews_restaurant_id ON restaurant_reviews(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_restaurant_analytics_restaurant_id ON restaurant_analytics(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_restaurant_analytics_date ON restaurant_analytics(date);

-- ============================================
-- TRIGGERS PARA ACTUALIZAR updated_at
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_restaurants_updated_at BEFORE UPDATE ON restaurants 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_restaurant_reservations_updated_at BEFORE UPDATE ON restaurant_reservations 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- VISTA PARA CONSULTAS COMUNES
-- ============================================

CREATE OR REPLACE VIEW restaurant_summary AS
SELECT 
    r.id,
    r.name,
    r.description,
    r.logo_url,
    r.is_active,
    r.is_open,
    COUNT(DISTINCT rt.id) as total_tables,
    COUNT(DISTINCT CASE WHEN rt.is_available THEN rt.id END) as available_tables,
    COUNT(DISTINCT rres.id) as total_reservations,
    COUNT(DISTINCT CASE WHEN rres.status = 'pending' THEN rres.id END) as pending_reservations,
    COALESCE(AVG(rrev.rating), 0) as average_rating,
    COUNT(DISTINCT rrev.id) as total_reviews
FROM restaurants r
LEFT JOIN restaurant_tables rt ON r.id = rt.restaurant_id
LEFT JOIN restaurant_reservations rres ON r.id = rres.restaurant_id
LEFT JOIN restaurant_reviews rrev ON r.id = rrev.restaurant_id
GROUP BY r.id, r.name, r.description, r.logo_url, r.is_active, r.is_open;

-- ============================================
-- COMENTARIOS
-- ============================================

COMMENT ON TABLE restaurants IS 'Tabla principal de restaurantes del sistema multi-tenant';
COMMENT ON TABLE restaurant_tables IS 'Mesas específicas de cada restaurante';
COMMENT ON TABLE restaurant_reservations IS 'Reservas por restaurante - aisladas de SODITA';
COMMENT ON TABLE restaurant_reviews IS 'Reviews por restaurante - separadas de SODITA';
COMMENT ON TABLE restaurant_analytics IS 'Analytics por restaurante para reportes';
COMMENT ON VIEW restaurant_summary IS 'Vista con resumen de métricas por restaurante';