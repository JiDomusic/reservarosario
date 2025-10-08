-- CONFIGURACION SUPABASE PARA SODITA
-- Solo lo esencial para integrar con Flutter

-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- TABLA DE MESAS DEL PISO SUPERIOR (10 mesas)
CREATE TABLE sodita_mesas (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    numero INTEGER UNIQUE NOT NULL CHECK (numero BETWEEN 1 AND 10),
    capacidad INTEGER NOT NULL CHECK (capacidad BETWEEN 2 AND 8),
    ubicacion VARCHAR(100),
    activa BOOLEAN DEFAULT TRUE,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLA DE RESERVAS
CREATE TABLE sodita_reservas (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    mesa_id UUID REFERENCES sodita_mesas(id),
    fecha DATE NOT NULL,
    hora TIME NOT NULL,
    personas INTEGER NOT NULL CHECK (personas > 0),
    nombre VARCHAR(200) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    comentarios TEXT,
    estado VARCHAR(20) DEFAULT 'confirmada' CHECK (estado IN ('confirmada', 'cancelada', 'completada', 'no_show', 'en_mesa')),
    codigo_confirmacion VARCHAR(10) UNIQUE NOT NULL,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- INDICES PARA RENDIMIENTO
CREATE INDEX idx_sodita_reservas_fecha ON sodita_reservas(fecha);
CREATE INDEX idx_sodita_reservas_mesa_fecha ON sodita_reservas(mesa_id, fecha);
CREATE INDEX idx_sodita_reservas_estado ON sodita_reservas(estado);
CREATE INDEX idx_sodita_reservas_codigo ON sodita_reservas(codigo_confirmacion);

-- TRIGGER PARA UPDATED_AT
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_sodita_reservas_updated_at 
    BEFORE UPDATE ON sodita_reservas 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- FUNCION PARA GENERAR CODIGO DE CONFIRMACION
CREATE OR REPLACE FUNCTION generate_confirmation_code()
RETURNS TRIGGER AS $$
BEGIN
    NEW.codigo_confirmacion = 'SOD' || LPAD((RANDOM() * 9999)::INTEGER::TEXT, 4, '0');
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_generate_confirmation_code 
    BEFORE INSERT ON sodita_reservas 
    FOR EACH ROW EXECUTE FUNCTION generate_confirmation_code();

-- INSERTAR LAS 10 MESAS
INSERT INTO sodita_mesas (numero, capacidad, ubicacion) VALUES 
(1, 2, 'Ventana frontal'),
(2, 2, 'Ventana lateral'),
(3, 4, 'Centro del salon'),
(4, 4, 'Cerca de la ventana'),
(5, 6, 'Mesa grande central'),
(6, 8, 'Mesa familiar grande'),
(7, 2, 'Rincon privado'),
(8, 4, 'Centro-derecha'),
(9, 4, 'Centro-izquierda'),
(10, 2, 'Mesa de la esquina');

-- FUNCION PARA VERIFICAR DISPONIBILIDAD
CREATE OR REPLACE FUNCTION verificar_disponibilidad_mesa(
    p_mesa_id UUID,
    p_fecha DATE,
    p_hora TIME,
    p_duracion_minutos INTEGER DEFAULT 120
) RETURNS BOOLEAN AS $$
DECLARE
    hora_fin TIME;
    conflictos INTEGER;
BEGIN
    hora_fin := p_hora + (p_duracion_minutos || ' minutes')::INTERVAL;
    
    SELECT COUNT(*) INTO conflictos
    FROM sodita_reservas 
    WHERE mesa_id = p_mesa_id 
    AND fecha = p_fecha 
    AND estado IN ('confirmada', 'en_mesa', 'completada')
    AND (
        (p_hora >= hora AND p_hora < (hora + INTERVAL '120 minutes')::TIME)
        OR
        (hora_fin > hora AND hora_fin <= (hora + INTERVAL '120 minutes')::TIME)
        OR
        (p_hora <= hora AND hora_fin >= (hora + INTERVAL '120 minutes')::TIME)
    );
    
    RETURN conflictos = 0;
END;
$$ LANGUAGE plpgsql;

-- POLITICAS RLS (Row Level Security)
ALTER TABLE sodita_mesas ENABLE ROW LEVEL SECURITY;
ALTER TABLE sodita_reservas ENABLE ROW LEVEL SECURITY;

-- Politica para leer mesas (todos pueden ver)
CREATE POLICY "Todos pueden ver mesas" ON sodita_mesas
    FOR SELECT USING (true);

-- Politica para insertar reservas (todos pueden crear)
CREATE POLICY "Todos pueden crear reservas" ON sodita_reservas
    FOR INSERT WITH CHECK (true);

-- Politica para leer reservas (todos pueden ver)
CREATE POLICY "Todos pueden ver reservas" ON sodita_reservas
    FOR SELECT USING (true);

-- Politica para actualizar reservas (solo admin autenticado)
CREATE POLICY "Solo admin puede actualizar reservas" ON sodita_reservas
    FOR UPDATE USING (auth.email() = 'equiz.rec@gmail.com');