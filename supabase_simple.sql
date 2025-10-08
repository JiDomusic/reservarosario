-- SODITA - SISTEMA DE RESERVAS SIMPLE
-- Solo las tablas necesarias para un restaurante

-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- TABLA DE RESERVAS (simplificada)
CREATE TABLE sodita_reservas (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    
    -- Datos de la reserva
    fecha DATE NOT NULL,
    hora TIME NOT NULL,
    personas INTEGER NOT NULL CHECK (personas > 0),
    
    -- Datos del cliente
    nombre VARCHAR(200) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    comentarios TEXT,
    
    -- Estado y gestión
    estado VARCHAR(20) DEFAULT 'confirmada' CHECK (estado IN ('confirmada', 'cancelada', 'completada', 'no_show')),
    codigo_confirmacion VARCHAR(10) UNIQUE NOT NULL,
    
    -- Timestamps
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLA DE CONFIGURACIÓN DEL RESTAURANTE
CREATE TABLE sodita_config (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    clave VARCHAR(100) UNIQUE NOT NULL,
    valor TEXT NOT NULL,
    descripcion TEXT,
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLA DE HORARIOS DISPONIBLES
CREATE TABLE sodita_horarios (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    dia_semana INTEGER CHECK (dia_semana BETWEEN 0 AND 6), -- 0=Domingo, 6=Sábado
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    max_reservas INTEGER DEFAULT 20,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ÍNDICES PARA RENDIMIENTO
CREATE INDEX idx_sodita_reservas_fecha ON sodita_reservas(fecha);
CREATE INDEX idx_sodita_reservas_hora ON sodita_reservas(fecha, hora);
CREATE INDEX idx_sodita_reservas_estado ON sodita_reservas(estado);
CREATE INDEX idx_sodita_reservas_telefono ON sodita_reservas(telefono);
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

-- FUNCIÓN PARA GENERAR CÓDIGO DE CONFIRMACIÓN
CREATE OR REPLACE FUNCTION generate_confirmation_code()
RETURNS TRIGGER AS $$
BEGIN
    NEW.codigo_confirmacion = 'SOD' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT), 1, 7));
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_generate_confirmation_code 
    BEFORE INSERT ON sodita_reservas 
    FOR EACH ROW EXECUTE FUNCTION generate_confirmation_code();

-- CONFIGURACIÓN INICIAL DEL RESTAURANTE
INSERT INTO sodita_config (clave, valor, descripcion) VALUES 
('nombre_restaurante', 'SODITA', 'Nombre del restaurante'),
('descripcion', 'Cocina casera • Ambiente familiar', 'Descripción del restaurante'),
('direccion', 'Rosario, Santa Fe', 'Dirección del restaurante'),
('telefono', '+54 341 555-0100', 'Teléfono del restaurante'),
('email', 'info@sodita.com.ar', 'Email del restaurante'),
('capacidad_maxima', '50', 'Capacidad máxima de personas'),
('duracion_turno_minutos', '120', 'Duración promedio por turno en minutos'),
('anticipacion_dias', '30', 'Días de anticipación para reservas'),
('anticipacion_horas_min', '2', 'Horas mínimas de anticipación');

-- HORARIOS DE ATENCIÓN (EJEMPLO)
INSERT INTO sodita_horarios (dia_semana, hora_inicio, hora_fin, max_reservas) VALUES 
-- Martes a Domingo (cerrado los lunes)
(2, '18:00', '23:00', 20), -- Martes
(3, '18:00', '23:00', 20), -- Miércoles
(4, '18:00', '23:00', 20), -- Jueves
(5, '18:00', '00:00', 25), -- Viernes
(6, '18:00', '00:00', 25), -- Sábado
(0, '18:00', '23:00', 20); -- Domingo

-- FUNCIÓN PARA VERIFICAR DISPONIBILIDAD
CREATE OR REPLACE FUNCTION verificar_disponibilidad(
    p_fecha DATE,
    p_hora TIME,
    p_personas INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    dia_semana INTEGER;
    horario_activo BOOLEAN;
    reservas_existentes INTEGER;
    max_permitidas INTEGER;
BEGIN
    -- Obtener día de la semana (0=domingo, 6=sábado)
    dia_semana := EXTRACT(DOW FROM p_fecha);
    
    -- Verificar si hay horario disponible para ese día y hora
    SELECT activo, max_reservas INTO horario_activo, max_permitidas
    FROM sodita_horarios 
    WHERE dia_semana = dia_semana 
    AND p_hora >= hora_inicio 
    AND p_hora <= hora_fin
    LIMIT 1;
    
    -- Si no hay horario configurado, no está disponible
    IF NOT FOUND OR NOT horario_activo THEN
        RETURN FALSE;
    END IF;
    
    -- Contar reservas existentes para esa fecha y hora
    SELECT COUNT(*) INTO reservas_existentes
    FROM sodita_reservas 
    WHERE fecha = p_fecha 
    AND hora = p_hora 
    AND estado IN ('confirmada', 'completada');
    
    -- Verificar si hay espacio disponible
    RETURN (reservas_existentes < max_permitidas);
END;
$$ LANGUAGE plpgsql;

-- FUNCIÓN PARA OBTENER HORARIOS DISPONIBLES
CREATE OR REPLACE FUNCTION obtener_horarios_disponibles(p_fecha DATE)
RETURNS TABLE(hora TIME, disponible BOOLEAN) AS $$
DECLARE
    dia_semana INTEGER;
    rec RECORD;
BEGIN
    dia_semana := EXTRACT(DOW FROM p_fecha);
    
    FOR rec IN 
        SELECT hora_inicio, hora_fin, max_reservas 
        FROM sodita_horarios 
        WHERE dia_semana = dia_semana AND activo = TRUE
    LOOP
        -- Generar horarios cada 30 minutos
        FOR hora IN 
            SELECT generate_series(
                rec.hora_inicio, 
                rec.hora_fin - INTERVAL '30 minutes', 
                INTERVAL '30 minutes'
            )::TIME
        LOOP
            disponible := verificar_disponibilidad(p_fecha, hora, 1);
            RETURN NEXT;
        END LOOP;
    END LOOP;
    
    RETURN;
END;
$$ LANGUAGE plpgsql;

-- VISTA PARA ESTADÍSTICAS DIARIAS
CREATE VIEW sodita_estadisticas_diarias AS
SELECT 
    fecha,
    COUNT(*) as total_reservas,
    SUM(personas) as total_personas,
    COUNT(CASE WHEN estado = 'completada' THEN 1 END) as reservas_completadas,
    COUNT(CASE WHEN estado = 'cancelada' THEN 1 END) as reservas_canceladas,
    COUNT(CASE WHEN estado = 'no_show' THEN 1 END) as no_shows
FROM sodita_reservas 
GROUP BY fecha 
ORDER BY fecha DESC;