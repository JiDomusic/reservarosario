-- ============================================
-- SCHEMA PARA SISTEMA MULTI-RESTAURANTE
-- NO TOCA NADA DE SODITA - SOLO AGREGA TABLAS NUEVAS
-- AUTENTICACIÓN: Supabase Auth para restaurantes
-- ============================================

-- Habilitar Row Level Security
ALTER TABLE IF EXISTS restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS restaurant_tables ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS restaurant_reservations ENABLE ROW LEVEL SECURITY;

-- Tabla principal de restaurantes
CREATE TABLE IF NOT EXISTS restaurants (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    logo_url TEXT,
    cover_image_url TEXT,
    address TEXT,
    phone VARCHAR(50),
    whatsapp VARCHAR(50),
    email VARCHAR(255) UNIQUE NOT NULL,
    auth_user_id UUID UNIQUE, -- Referencia a Supabase auth.users
    total_tables INTEGER DEFAULT 10,
    primary_color VARCHAR(7) DEFAULT '#F86704',
    secondary_color VARCHAR(7) DEFAULT '#10B981',
    is_active BOOLEAN DEFAULT true,
    is_open BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Mesas por restaurante
CREATE TABLE IF NOT EXISTS restaurant_tables (
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
CREATE TABLE IF NOT EXISTS restaurant_reservations (
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
    status VARCHAR(20) DEFAULT 'pending', -- pending, confirmed, cancelled, completed
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Reviews por restaurante
CREATE TABLE IF NOT EXISTS restaurant_reviews (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    reservation_id UUID REFERENCES restaurant_reservations(id),
    customer_name VARCHAR(255),
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    is_public BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Analytics por restaurante
CREATE TABLE IF NOT EXISTS restaurant_analytics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    total_reservations INTEGER DEFAULT 0,
    confirmed_reservations INTEGER DEFAULT 0,
    cancelled_reservations INTEGER DEFAULT 0,
    total_customers INTEGER DEFAULT 0,
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    total_reviews INTEGER DEFAULT 0,
    revenue DECIMAL(10,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(restaurant_id, date)
);

-- Horarios por restaurante
CREATE TABLE IF NOT EXISTS restaurant_schedules (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6), -- 0=Sunday, 6=Saturday
    open_time TIME,
    close_time TIME,
    is_closed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(restaurant_id, day_of_week)
);

-- ============================================
-- INSERTAR 10 RESTAURANTES DEMO
-- ============================================

-- NOTA: Los auth_user_id se llenarán cuando se registren en Supabase Auth
INSERT INTO restaurants (name, description, email, total_tables, phone, address) VALUES
('AMELIE PETIT CAFE', 'Café francés con ambiente íntimo y deliciosa repostería artesanal.

🏢 LAYOUT FÍSICO:
• Sala principal: 12 mesas disponibles para reservas
• Capacidad total: 36 personas
• Mesas redondas para 2-3 personas (estilo parisino)
• Rincón de lectura con sillones vintage
• Barra de café para 4 personas
• Terraza cubierta con 3 mesas
• Distribución: 70% interior, 30% terraza

📍 Todas las mesas están disponibles para reservas online. Ambiente romántico e íntimo perfecto para parejas y reuniones pequeñas.', 'admin@ameliepetitcafe.com', 12, '+54 341 456-7890', 'Av. Pellegrini 1234, Rosario'),

('LA COCINA DE MAMA', 'Comida casera argentina con el sabor de la abuela.

🏢 LAYOUT FÍSICO:
• Comedor principal: 15 mesas familiares
• Capacidad total: 60 personas
• Mesas grandes para 4-6 personas (estilo familiar)
• Mesa comunal para 8 personas
• Rincón infantil con mesa especial
• Patio interno con parrilla a la vista
• Distribución: Ambiente hogareño y cálido

📍 Especialistas en reuniones familiares. La mesa comunal es ideal para grupos grandes. Reservas recomendadas para fines de semana.', 'admin@lacocinademama.com', 15, '+54 341 456-7891', 'San Martín 567, Rosario'),

('PIZZA CORNER', 'Las mejores pizzas artesanales de la ciudad.

🏢 LAYOUT FÍSICO:
• Salón principal: 20 mesas variadas
• Capacidad total: 80 personas
• Mesas altas para 2-4 personas (vista al horno)
• Mesas bajas familiares para 4-6 personas
• Booth privados para parejas
• Barra con vista a la cocina abierta
• Terraza amplia para 6 mesas
• Distribución: 60% interior, 40% terraza

📍 El horno de leña está a la vista desde todas las mesas. Terraza climatizada abierta todo el año.', 'admin@pizzacorner.com', 20, '+54 341 456-7892', 'Córdoba 890, Rosario'),

('SUSHI ZEN', 'Auténtica cocina japonesa y sushi fresco.

🏢 LAYOUT FÍSICO:
• Área principal: 18 mesas estilo japonés
• Capacidad total: 54 personas
• Barra de sushi para 8 personas (show cooking)
• Mesas bajas con tatami para 4 personas
• Booths privados para 2-4 personas
• Sala privada para 6 personas (reserva especial)
• Ambiente zen con decoración minimalista
• Distribución: Diseño asiático auténtico

📍 La barra de sushi ofrece experiencia interactiva con el chef. Sala privada requiere reserva con 24hs de anticipación.', 'admin@sushizen.com', 18, '+54 341 456-7893', 'Montevideo 345, Rosario'),

('PARRILLA DON CARLOS', 'Carnes premium y parrilla tradicional argentina.

🏢 LAYOUT FÍSICO:
• Salón principal: 25 mesas para asados
• Capacidad total: 125 personas
• Mesas familiares para 4-8 personas
• Barra alta con vista a la parrilla
• Quincho techado para 12 personas
• Sector VIP para 16 personas
• Parrilla abierta como espectáculo
• Distribución: Ambiente gauchesco tradicional

📍 La parrilla está a la vista de todos los comensales. El quincho es ideal para celebraciones. Sector VIP requiere reserva anticipada.', 'admin@parrilladoncarlos.com', 25, '+54 341 456-7894', 'Rioja 678, Rosario'),

('VERDE NATURAL', 'Cocina vegetariana y vegana saludable.

🏢 LAYOUT FÍSICO:
• Salón eco-friendly: 14 mesas orgánicas
• Capacidad total: 42 personas
• Mesas de madera reciclada para 2-4 personas
• Rincón de lectura con plantas
• Barra de jugos naturales
• Jardín vertical como decoración
• Terraza con huerta orgánica
• Distribución: 100% materiales sustentables

📍 Ambiente completamente eco-friendly. Terraza con vista a la huerta donde crecen los ingredientes. Ideal para veganos y vegetarianos.', 'admin@verdenatural.com', 14, '+54 341 456-7895', 'Entre Ríos 234, Rosario'),

('MARISCOS DEL PUERTO', 'Pescados y mariscos frescos del día.

🏢 LAYOUT FÍSICO:
• Salón náutico: 16 mesas temáticas
• Capacidad total: 64 personas
• Mesas con vista al display de mariscos
• Barra cruda para 6 personas
• Mesas altas estilo puerto
• Terraza con decoración marinera
• Pecera gigante como atracción
• Distribución: Temática 100% marina

📍 Display de mariscos frescos visible desde todas las mesas. La barra cruda ofrece ostras y ceviches al momento. Ambiente portuario auténtico.', 'admin@mariscospuerto.com', 16, '+54 341 456-7896', 'Av. Belgrano 789, Rosario'),

('TACO LOCO', 'Comida mexicana auténtica y picante.

🏢 LAYOUT FÍSICO:
• Cantina mexicana: 22 mesas coloridas
• Capacidad total: 88 personas
• Mesas largas para grupos grandes
• Barra de tequila con 12 banquetas
• Booths privados estilo hacienda
• Escenario para mariachis (fines de semana)
• Decoración típica mexicana
• Distribución: Fiesta garantizada

📍 Ambiente festivo con música en vivo los fines de semana. La barra de tequila tiene más de 50 variedades. Ideal para celebraciones grupales.', 'admin@tacoloco.com', 22, '+54 341 456-7897', 'Mitre 456, Rosario'),

('PASTA BELLA', 'Pastas artesanales y cocina italiana tradicional.

🏢 LAYOUT FÍSICO:
• Trattoria italiana: 19 mesas familiares
• Capacidad total: 76 personas
• Mesas para 2-6 personas estilo toscano
• Mesa del chef para 8 personas
• Cocina abierta con vista al trabajo artesanal
• Cava de vinos a la vista
• Decoración italiana auténtica
• Distribución: Como en la Toscana

📍 Pasta fresca hecha a la vista en la cocina abierta. La mesa del chef ofrece experiencia gastronómica única. Cava con vinos importados de Italia.', 'admin@pastabella.com', 19, '+54 341 456-7898', 'Urquiza 123, Rosario'),

('BRUNCH CLUB', 'Desayunos gourmet y brunch todo el día.

🏢 LAYOUT FÍSICO:
• Café moderno: 13 mesas estilo NY
• Capacidad total: 39 personas
• Mesas altas para laptop y trabajo
• Booths cómodos para brunch largo
• Barra de café de especialidad
• Rincón de lectura con revistas
• Terraza perfect para desayunos al sol
• Distribución: Estilo coffee shop neoyorquino

📍 WiFi gratis y mesas cómodas para trabajar. Barra de café con baristas especializados. Terraza ideal para brunchs de fin de semana.', 'admin@brunchclub.com', 13, '+54 341 456-7899', 'Sarmiento 321, Rosario');

-- ============================================
-- CREAR MESAS PARA CADA RESTAURANTE
-- ============================================

-- Función para crear mesas automáticamente
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
                CASE WHEN i = 0 THEN '10:00:00'::TIME ELSE '08:00:00'::TIME END, -- Domingo abre más tarde
                CASE WHEN i IN (0,6) THEN '00:00:00'::TIME ELSE '23:00:00'::TIME END, -- Fin de semana hasta más tarde
                false
            );
        END LOOP;
    END LOOP;
END $$;

-- ============================================
-- ÍNDICES PARA PERFORMANCE
-- ============================================

CREATE INDEX IF NOT EXISTS idx_restaurants_email ON restaurants(email);
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
-- POLÍTICAS RLS (Row Level Security) PARA SUPABASE AUTH
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

-- Política pública para lectura de restaurantes (para usuarios públicos)
CREATE POLICY "Public can view active restaurants" ON restaurants
    FOR SELECT USING (is_active = true);

-- Política pública para ver mesas disponibles (para hacer reservas)
CREATE POLICY "Public can view available tables" ON restaurant_tables
    FOR SELECT USING (
        is_available = true AND 
        restaurant_id IN (SELECT id FROM restaurants WHERE is_active = true)
    );

-- Política para que usuarios públicos puedan crear reservas
CREATE POLICY "Public can create reservations" ON restaurant_reservations
    FOR INSERT WITH CHECK (
        restaurant_id IN (SELECT id FROM restaurants WHERE is_active = true AND is_open = true)
    );

-- ============================================
-- VIEWS PARA CONSULTAS COMUNES
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