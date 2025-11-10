-- ================================================
-- SISTEMA MULTI-RESTAURANTE COMPLETO
-- ================================================

-- 1. TABLA PRINCIPAL DE RESTAURANTES
CREATE TABLE IF NOT EXISTS restaurantes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    slug VARCHAR(50) UNIQUE NOT NULL, -- para URLs: sodita, palacio-tango, etc
    descripcion TEXT,
    direccion TEXT NOT NULL,
    telefono VARCHAR(20),
    email VARCHAR(100),
    sitio_web VARCHAR(200),
    
    -- Configuración visual
    logo_url TEXT,
    imagen_principal TEXT,
    color_primario VARCHAR(7) DEFAULT '#1976d2', -- hex color
    color_secundario VARCHAR(7) DEFAULT '#42a5f5',
    
    -- Horarios (JSON)
    horarios JSONB DEFAULT '{"lunes": {"abierto": true, "apertura": "18:00", "cierre": "01:00"}, "martes": {"abierto": true, "apertura": "18:00", "cierre": "01:00"}, "miercoles": {"abierto": true, "apertura": "18:00", "cierre": "01:00"}, "jueves": {"abierto": true, "apertura": "18:00", "cierre": "01:00"}, "viernes": {"abierto": true, "apertura": "18:00", "cierre": "02:00"}, "sabado": {"abierto": true, "apertura": "18:00", "cierre": "02:00"}, "domingo": {"abierto": false}}',
    
    -- Configuración de reservas
    duracion_reserva_minutos INTEGER DEFAULT 120,
    tolerancia_llegada_minutos INTEGER DEFAULT 15,
    
    -- Admin y suscripción
    admin_email VARCHAR(100) NOT NULL,
    admin_password_hash TEXT, -- Para login independiente
    suscripcion_activa BOOLEAN DEFAULT FALSE,
    fecha_vencimiento_suscripcion DATE,
    
    -- Configuración de pagos
    alias_banco TEXT,
    cbu_banco TEXT,
    monto_suscripcion DECIMAL(10,2) DEFAULT 50000.00,
    
    -- Estados
    activo BOOLEAN DEFAULT TRUE,
    verificado BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. TABLA DE MESAS POR RESTAURANTE
CREATE TABLE IF NOT EXISTS mesas_restaurante (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    restaurante_id UUID REFERENCES restaurantes(id) ON DELETE CASCADE,
    numero INTEGER NOT NULL,
    capacidad INTEGER NOT NULL CHECK (capacidad BETWEEN 2 AND 50),
    ubicacion VARCHAR(100),
    descripcion TEXT,
    imagen_url TEXT, -- Foto específica de la mesa
    activa BOOLEAN DEFAULT TRUE,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(restaurante_id, numero) -- Cada restaurante puede tener mesa 1, 2, etc.
);

-- 3. TABLA DE RESERVAS POR RESTAURANTE
CREATE TABLE IF NOT EXISTS reservas_restaurante (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    restaurante_id UUID REFERENCES restaurantes(id) ON DELETE CASCADE,
    mesa_id UUID REFERENCES mesas_restaurante(id) ON DELETE CASCADE,
    
    -- Datos de la reserva
    fecha DATE NOT NULL,
    hora TIME NOT NULL,
    personas INTEGER NOT NULL CHECK (personas > 0),
    
    -- Datos del cliente
    nombre VARCHAR(200) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    comentarios TEXT,
    
    -- Estado y código
    estado VARCHAR(20) DEFAULT 'confirmada' CHECK (estado IN ('confirmada', 'cancelada', 'completada', 'no_show', 'en_mesa', 'expirada')),
    codigo_confirmacion VARCHAR(10) UNIQUE NOT NULL,
    
    -- Timestamps
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. INSERTAR SODITA COMO PRIMER RESTAURANTE
INSERT INTO restaurantes (
    nombre, slug, descripcion, direccion, telefono, 
    admin_email, logo_url, imagen_principal,
    color_primario, color_secundario, suscripcion_activa
) VALUES (
    'SODITA', 
    'sodita', 
    'Comida gourmet en el corazón de Rosario. Experiencia gastronómica única con ambiente sofisticado.',
    'Laprida 1301, Rosario 2000',
    '+54 341 123-4567',
    'equiz.rec@gmail.com',
    'https://example.com/sodita-logo.png',
    'https://example.com/sodita-main.jpg',
    '#2E7D32', -- Verde elegante
    '#4CAF50', -- Verde más claro
    TRUE
) ON CONFLICT (slug) DO NOTHING;

-- 5. MIGRAR MESAS DE SODITA AL NUEVO SISTEMA
INSERT INTO mesas_restaurante (restaurante_id, numero, capacidad, ubicacion)
SELECT 
    (SELECT id FROM restaurantes WHERE slug = 'sodita'),
    numero,
    capacidad,
    ubicacion
FROM sodita_mesas
ON CONFLICT (restaurante_id, numero) DO NOTHING;

-- 6. MIGRAR RESERVAS DE SODITA AL NUEVO SISTEMA
INSERT INTO reservas_restaurante (restaurante_id, mesa_id, fecha, hora, personas, nombre, telefono, email, comentarios, estado, codigo_confirmacion, creado_en, actualizado_en)
SELECT 
    (SELECT id FROM restaurantes WHERE slug = 'sodita'),
    mr.id, -- nueva mesa_id del sistema unificado
    sr.fecha,
    sr.hora,
    sr.personas,
    sr.nombre,
    sr.telefono,
    sr.email,
    sr.comentarios,
    sr.estado,
    sr.codigo_confirmacion,
    sr.creado_en,
    sr.actualizado_en
FROM sodita_reservas sr
JOIN sodita_mesas sm ON sr.mesa_id = sm.id
JOIN mesas_restaurante mr ON mr.numero = sm.numero 
    AND mr.restaurante_id = (SELECT id FROM restaurantes WHERE slug = 'sodita')
ON CONFLICT (codigo_confirmacion) DO NOTHING;

-- 7. FUNCIONES PARA CÓDIGOS DE CONFIRMACIÓN DINÁMICOS
CREATE OR REPLACE FUNCTION generate_restaurant_confirmation_code()
RETURNS TRIGGER AS $$
DECLARE
    restaurant_prefix VARCHAR(3);
BEGIN
    -- Obtener prefijo del restaurante (primeras 3 letras en mayúscula)
    SELECT UPPER(LEFT(slug, 3)) INTO restaurant_prefix
    FROM restaurantes 
    WHERE id = NEW.restaurante_id;
    
    -- Generar código único
    NEW.codigo_confirmacion = restaurant_prefix || LPAD((RANDOM() * 9999)::INTEGER::TEXT, 4, '0');
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 8. FUNCIÓN PARA AUTO-UPDATE DE TIMESTAMPS
CREATE OR REPLACE FUNCTION update_restaurant_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 9. TRIGGERS
CREATE TRIGGER trigger_generate_restaurant_confirmation_code 
    BEFORE INSERT ON reservas_restaurante 
    FOR EACH ROW EXECUTE FUNCTION generate_restaurant_confirmation_code();

CREATE TRIGGER update_reservas_restaurant_updated_at 
    BEFORE UPDATE ON reservas_restaurante 
    FOR EACH ROW EXECUTE FUNCTION update_restaurant_updated_at();

CREATE TRIGGER update_restaurants_updated_at 
    BEFORE UPDATE ON restaurantes 
    FOR EACH ROW EXECUTE FUNCTION update_restaurant_updated_at();

-- 10. ÍNDICES PARA OPTIMIZACIÓN
CREATE INDEX idx_reservas_restaurante_fecha ON reservas_restaurante(fecha);
CREATE INDEX idx_reservas_restaurante_mesa_fecha ON reservas_restaurante(mesa_id, fecha);
CREATE INDEX idx_reservas_restaurante_estado ON reservas_restaurante(estado);
CREATE INDEX idx_reservas_restaurante_codigo ON reservas_restaurante(codigo_confirmacion);
CREATE INDEX idx_reservas_restaurante_id ON reservas_restaurante(restaurante_id);
CREATE INDEX idx_mesas_restaurante_id ON mesas_restaurante(restaurante_id);

-- 11. RLS POLÍTICAS
ALTER TABLE restaurantes ENABLE ROW LEVEL SECURITY;
ALTER TABLE mesas_restaurante ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservas_restaurante ENABLE ROW LEVEL SECURITY;

-- Políticas para restaurantes
CREATE POLICY "Todos pueden ver restaurantes activos" ON restaurantes
    FOR SELECT USING (activo = true);

-- Políticas para mesas
CREATE POLICY "Todos pueden ver mesas de restaurantes activos" ON mesas_restaurante
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM restaurantes WHERE id = restaurante_id AND activo = true)
    );

-- Políticas para reservas
CREATE POLICY "Todos pueden crear reservas" ON reservas_restaurante
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM restaurantes WHERE id = restaurante_id AND activo = true)
    );

CREATE POLICY "Todos pueden ver reservas" ON reservas_restaurante
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM restaurantes WHERE id = restaurante_id AND activo = true)
    );

CREATE POLICY "Todos pueden actualizar reservas" ON reservas_restaurante
    FOR UPDATE USING (true);

-- 12. VERIFICACIONES
SELECT 'RESTAURANTES' as tabla, COUNT(*) as cantidad FROM restaurantes
UNION ALL
SELECT 'MESAS_RESTAURANTE' as tabla, COUNT(*) as cantidad FROM mesas_restaurante
UNION ALL
SELECT 'RESERVAS_RESTAURANTE' as tabla, COUNT(*) as cantidad FROM reservas_restaurante;

-- ================================================
-- SISTEMA MULTI-RESTAURANTE LISTO
-- ================================================