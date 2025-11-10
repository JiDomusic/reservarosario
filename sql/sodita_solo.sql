-- ================================================
-- SCRIPT SOLO PARA SODITA (SIN CONFLICTOS)
-- ================================================
-- Ejecutar en Supabase SQL Editor

-- 1. LIMPIAR SOLO TABLAS DE SODITA
DROP TABLE IF EXISTS sodita_reservas CASCADE;
DROP TABLE IF EXISTS sodita_mesas CASCADE;

-- 2. EXTENSIONES NECESARIAS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 3. CREAR TABLA DE MESAS (11 mesas, 4-50 personas)
CREATE TABLE sodita_mesas (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    numero INTEGER UNIQUE NOT NULL CHECK (numero BETWEEN 1 AND 11),
    capacidad INTEGER NOT NULL CHECK (capacidad BETWEEN 2 AND 50),
    ubicacion VARCHAR(100),
    activa BOOLEAN DEFAULT TRUE,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. CREAR TABLA DE RESERVAS
CREATE TABLE sodita_reservas (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    mesa_id UUID REFERENCES sodita_mesas(id),
    fecha DATE NOT NULL,
    hora TIME NOT NULL,
    personas INTEGER NOT NULL CHECK (personas > 0),
    nombre VARCHAR(200) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    comentarios TEXT,
    estado VARCHAR(20) DEFAULT 'confirmada' CHECK (estado IN ('confirmada', 'cancelada', 'completada', 'no_show', 'en_mesa')),
    codigo_confirmacion VARCHAR(10) UNIQUE NOT NULL,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. INSERTAR LAS 11 MESAS DE SODITA
INSERT INTO sodita_mesas (numero, capacidad, ubicacion) VALUES 
(1, 4, 'Ventana frontal'),
(2, 6, 'Ventana lateral'),
(3, 4, 'Centro del salon'),
(4, 8, 'Mesa familiar grande'),
(5, 2, 'Mesa romántica'),
(6, 4, 'Cerca de la ventana'),
(7, 6, 'Mesa grande central'),
(8, 4, 'Rincon privado'),
(9, 8, 'Mesa de celebraciones'),
(10, 12, 'Living con sofás'),
(11, 50, 'Todo el salón con capacidad de 50 personas');

-- 6. FUNCIÓN ESPECÍFICA PARA SODITA (sin conflictos)
CREATE OR REPLACE FUNCTION generate_sodita_confirmation_code()
RETURNS TRIGGER AS $$
BEGIN
    NEW.codigo_confirmacion = 'SOD' || LPAD((RANDOM() * 9999)::INTEGER::TEXT, 4, '0');
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 7. FUNCIÓN ESPECÍFICA PARA TIMESTAMPS DE SODITA
CREATE OR REPLACE FUNCTION update_sodita_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 8. TRIGGERS ESPECÍFICOS PARA SODITA
CREATE TRIGGER trigger_generate_sodita_confirmation_code 
    BEFORE INSERT ON sodita_reservas 
    FOR EACH ROW EXECUTE FUNCTION generate_sodita_confirmation_code();

CREATE TRIGGER update_sodita_reservas_updated_at 
    BEFORE UPDATE ON sodita_reservas 
    FOR EACH ROW EXECUTE FUNCTION update_sodita_updated_at();

-- 9. ÍNDICES PARA OPTIMIZACIÓN
CREATE INDEX idx_sodita_reservas_fecha ON sodita_reservas(fecha);
CREATE INDEX idx_sodita_reservas_mesa_fecha ON sodita_reservas(mesa_id, fecha);
CREATE INDEX idx_sodita_reservas_estado ON sodita_reservas(estado);
CREATE INDEX idx_sodita_reservas_codigo ON sodita_reservas(codigo_confirmacion);

-- 10. CONFIGURAR RLS (Row Level Security)
ALTER TABLE sodita_mesas ENABLE ROW LEVEL SECURITY;
ALTER TABLE sodita_reservas ENABLE ROW LEVEL SECURITY;

-- 11. POLÍTICAS RLS - PERMITIR ACCESO PÚBLICO
CREATE POLICY "Todos pueden ver mesas de sodita" ON sodita_mesas
    FOR SELECT USING (true);

CREATE POLICY "Todos pueden crear reservas en sodita" ON sodita_reservas
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Todos pueden ver reservas de sodita" ON sodita_reservas
    FOR SELECT USING (true);

CREATE POLICY "Todos pueden actualizar reservas de sodita" ON sodita_reservas
    FOR UPDATE USING (true);

-- 12. VERIFICAR QUE TODO ESTÉ CORRECTO
SELECT 'MESAS CREADAS' as resultado, COUNT(*) as cantidad FROM sodita_mesas
UNION ALL
SELECT 'RESERVAS EXISTENTES' as resultado, COUNT(*) as cantidad FROM sodita_reservas;

-- 13. MOSTRAR LAS MESAS PARA VERIFICAR
SELECT numero, capacidad, ubicacion FROM sodita_mesas ORDER BY numero;

-- ================================================
-- ¡LISTO! SODITA AHORA FUNCIONARÁ PERFECTAMENTE
-- ================================================