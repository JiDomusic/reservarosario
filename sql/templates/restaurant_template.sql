-- ================================================
-- PLANTILLA SQL PARA NUEVO RESTAURANTE
-- ================================================
-- Reemplazar {RESTAURANT_NAME} con el nombre del restaurante
-- Reemplazar {TABLE_COUNT} con el número de mesas
-- Reemplazar {PREFIX} con el prefijo de código (ej: PAL, TAN, etc.)

-- 1. LIMPIAR TABLAS EXISTENTES (si existen)
DROP TABLE IF EXISTS {RESTAURANT_NAME}_reservas CASCADE;
DROP TABLE IF EXISTS {RESTAURANT_NAME}_mesas CASCADE;

-- 2. EXTENSIONES NECESARIAS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 3. CREAR TABLA DE MESAS
CREATE TABLE {RESTAURANT_NAME}_mesas (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    numero INTEGER UNIQUE NOT NULL CHECK (numero BETWEEN 1 AND {TABLE_COUNT}),
    capacidad INTEGER NOT NULL CHECK (capacidad BETWEEN 2 AND 50),
    ubicacion VARCHAR(100),
    activa BOOLEAN DEFAULT TRUE,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. CREAR TABLA DE RESERVAS
CREATE TABLE {RESTAURANT_NAME}_reservas (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    mesa_id UUID REFERENCES {RESTAURANT_NAME}_mesas(id),
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

-- 5. INSERTAR MESAS (PERSONALIZAR SEGÚN RESTAURANTE)
-- INSERT INTO {RESTAURANT_NAME}_mesas (numero, capacidad, ubicacion) VALUES 
-- (1, 4, 'Ubicación mesa 1'),
-- (2, 6, 'Ubicación mesa 2'),
-- ... completar según layout del restaurante

-- 6. FUNCIÓN PARA GENERAR CÓDIGO DE CONFIRMACIÓN
CREATE OR REPLACE FUNCTION generate_{RESTAURANT_NAME}_confirmation_code()
RETURNS TRIGGER AS $$
BEGIN
    NEW.codigo_confirmacion = '{PREFIX}' || LPAD((RANDOM() * 9999)::INTEGER::TEXT, 4, '0');
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 7. FUNCIÓN PARA AUTO-UPDATE DE TIMESTAMPS
CREATE OR REPLACE FUNCTION update_{RESTAURANT_NAME}_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 8. TRIGGERS
CREATE TRIGGER trigger_generate_{RESTAURANT_NAME}_confirmation_code 
    BEFORE INSERT ON {RESTAURANT_NAME}_reservas 
    FOR EACH ROW EXECUTE FUNCTION generate_{RESTAURANT_NAME}_confirmation_code();

CREATE TRIGGER update_{RESTAURANT_NAME}_reservas_updated_at 
    BEFORE UPDATE ON {RESTAURANT_NAME}_reservas 
    FOR EACH ROW EXECUTE FUNCTION update_{RESTAURANT_NAME}_updated_at_column();

-- 9. ÍNDICES PARA OPTIMIZACIÓN
CREATE INDEX idx_{RESTAURANT_NAME}_reservas_fecha ON {RESTAURANT_NAME}_reservas(fecha);
CREATE INDEX idx_{RESTAURANT_NAME}_reservas_mesa_fecha ON {RESTAURANT_NAME}_reservas(mesa_id, fecha);
CREATE INDEX idx_{RESTAURANT_NAME}_reservas_estado ON {RESTAURANT_NAME}_reservas(estado);
CREATE INDEX idx_{RESTAURANT_NAME}_reservas_codigo ON {RESTAURANT_NAME}_reservas(codigo_confirmacion);

-- 10. CONFIGURAR RLS (Row Level Security)
ALTER TABLE {RESTAURANT_NAME}_mesas ENABLE ROW LEVEL SECURITY;
ALTER TABLE {RESTAURANT_NAME}_reservas ENABLE ROW LEVEL SECURITY;

-- 11. POLÍTICAS RLS - PERMITIR ACCESO PÚBLICO
CREATE POLICY "Todos pueden ver mesas de {RESTAURANT_NAME}" ON {RESTAURANT_NAME}_mesas
    FOR SELECT USING (true);

CREATE POLICY "Todos pueden crear reservas en {RESTAURANT_NAME}" ON {RESTAURANT_NAME}_reservas
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Todos pueden ver reservas de {RESTAURANT_NAME}" ON {RESTAURANT_NAME}_reservas
    FOR SELECT USING (true);

CREATE POLICY "Todos pueden actualizar reservas de {RESTAURANT_NAME}" ON {RESTAURANT_NAME}_reservas
    FOR UPDATE USING (true);

-- 12. VERIFICAR QUE TODO ESTÉ CORRECTO
SELECT 'MESAS CREADAS' as resultado, COUNT(*) as cantidad FROM {RESTAURANT_NAME}_mesas
UNION ALL
SELECT 'RESERVAS EXISTENTES' as resultado, COUNT(*) as cantidad FROM {RESTAURANT_NAME}_reservas;