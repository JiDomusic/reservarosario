-- SODITA RESTAURANT - SISTEMA DE RESERVAS MODERNO
-- Gestión de 10 mesas en el piso superior

-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- TABLA DE MESAS DEL PISO SUPERIOR
CREATE TABLE sodita_mesas (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    numero INTEGER UNIQUE NOT NULL CHECK (numero BETWEEN 1 AND 10),
    capacidad INTEGER NOT NULL CHECK (capacidad BETWEEN 2 AND 8),
    ubicacion VARCHAR(100), -- 'ventana', 'centro', 'rincón', etc.
    caracteristicas TEXT[], -- ['romántica', 'familiar', 'vista', 'privada']
    activa BOOLEAN DEFAULT TRUE,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLA DE RESERVAS
CREATE TABLE sodita_reservas (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    
    -- Referencia a la mesa
    mesa_id UUID REFERENCES sodita_mesas(id),
    
    -- Datos de la reserva
    fecha DATE NOT NULL,
    hora TIME NOT NULL,
    duracion_minutos INTEGER DEFAULT 120,
    personas INTEGER NOT NULL CHECK (personas > 0),
    
    -- Datos del cliente
    nombre VARCHAR(200) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    comentarios TEXT,
    ocasion VARCHAR(50), -- 'cumpleaños', 'aniversario', 'cita', 'trabajo', 'familiar'
    
    -- Estado y gestión
    estado VARCHAR(20) DEFAULT 'confirmada' CHECK (estado IN ('confirmada', 'cancelada', 'completada', 'no_show', 'en_mesa')),
    codigo_confirmacion VARCHAR(10) UNIQUE NOT NULL,
    
    -- Notificaciones
    recordatorio_enviado BOOLEAN DEFAULT FALSE,
    confirmacion_enviada BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    confirmado_en TIMESTAMP WITH TIME ZONE,
    sentado_en TIMESTAMP WITH TIME ZONE,
    completado_en TIMESTAMP WITH TIME ZONE
);

-- TABLA DE BLOQUES DE TIEMPO (para gestión avanzada)
CREATE TABLE sodita_bloques_tiempo (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    mesa_id UUID REFERENCES sodita_mesas(id),
    fecha DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    reserva_id UUID REFERENCES sodita_reservas(id),
    bloqueado BOOLEAN DEFAULT FALSE,
    motivo_bloqueo VARCHAR(200),
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TABLA DE CONFIGURACIÓN
CREATE TABLE sodita_configuracion (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    clave VARCHAR(100) UNIQUE NOT NULL,
    valor JSONB NOT NULL,
    descripcion TEXT,
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ÍNDICES PARA RENDIMIENTO
CREATE INDEX idx_sodita_reservas_fecha ON sodita_reservas(fecha);
CREATE INDEX idx_sodita_reservas_mesa_fecha ON sodita_reservas(mesa_id, fecha);
CREATE INDEX idx_sodita_reservas_estado ON sodita_reservas(estado);
CREATE INDEX idx_sodita_reservas_codigo ON sodita_reservas(codigo_confirmacion);
CREATE INDEX idx_sodita_bloques_mesa_fecha ON sodita_bloques_tiempo(mesa_id, fecha);
CREATE INDEX idx_sodita_mesas_activa ON sodita_mesas(activa);

-- TRIGGERS
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
    NEW.codigo_confirmacion = 'SOD' || LPAD((RANDOM() * 9999)::INTEGER::TEXT, 4, '0');
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_generate_confirmation_code 
    BEFORE INSERT ON sodita_reservas 
    FOR EACH ROW EXECUTE FUNCTION generate_confirmation_code();

-- INSERTAR LAS 10 MESAS DEL PISO SUPERIOR
INSERT INTO sodita_mesas (numero, capacidad, ubicacion, caracteristicas) VALUES 
(1, 2, 'Ventana frontal', ARRAY['romántica', 'vista']),
(2, 2, 'Ventana lateral', ARRAY['íntima', 'vista']),
(3, 4, 'Centro del salón', ARRAY['familiar', 'espaciosa']),
(4, 4, 'Cerca de la ventana', ARRAY['luminosa', 'familiar']),
(5, 6, 'Mesa grande central', ARRAY['grupo', 'celebraciones']),
(6, 8, 'Mesa familiar grande', ARRAY['familia', 'reuniones']),
(7, 2, 'Rincón privado', ARRAY['privada', 'romántica']),
(8, 4, 'Centro-derecha', ARRAY['cómoda', 'versátil']),
(9, 4, 'Centro-izquierda', ARRAY['animada', 'social']),
(10, 2, 'Mesa de la esquina', ARRAY['tranquila', 'íntima']);

-- CONFIGURACIÓN INICIAL
INSERT INTO sodita_configuracion (clave, valor, descripcion) VALUES 
('info_restaurante', '{
    "nombre": "SODITA",
    "descripcion": "Cocina casera • Ambiente familiar",
    "direccion": "Piso Superior, Rosario, Santa Fe",
    "telefono": "+54 341 555-0100",
    "email": "reservas@sodita.com.ar",
    "horarios": {
        "martes": {"inicio": "18:00", "fin": "23:00"},
        "miercoles": {"inicio": "18:00", "fin": "23:00"},
        "jueves": {"inicio": "18:00", "fin": "23:00"},
        "viernes": {"inicio": "18:00", "fin": "00:00"},
        "sabado": {"inicio": "18:00", "fin": "00:00"},
        "domingo": {"inicio": "18:00", "fin": "23:00"}
    }
}', 'Información básica del restaurante'),

('configuracion_reservas', '{
    "duracion_default_minutos": 120,
    "anticipacion_maxima_dias": 30,
    "anticipacion_minima_horas": 2,
    "cancelacion_gratuita_horas": 24,
    "capacidad_total": 38,
    "turnos_por_mesa": 2
}', 'Configuración de reservas'),

('notificaciones', '{
    "recordatorio_horas": 2,
    "confirmacion_automatica": true,
    "whatsapp_enabled": true,
    "email_enabled": true
}', 'Configuración de notificaciones');

-- FUNCIÓN PARA VERIFICAR DISPONIBILIDAD DE MESA
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
    
    -- Verificar conflictos con reservas existentes
    SELECT COUNT(*) INTO conflictos
    FROM sodita_reservas 
    WHERE mesa_id = p_mesa_id 
    AND fecha = p_fecha 
    AND estado IN ('confirmada', 'en_mesa', 'completada')
    AND (
        -- La nueva reserva empieza durante una existente
        (p_hora >= hora AND p_hora < (hora + (duracion_minutos || ' minutes')::INTERVAL)::TIME)
        OR
        -- La nueva reserva termina durante una existente  
        (hora_fin > hora AND hora_fin <= (hora + (duracion_minutos || ' minutes')::INTERVAL)::TIME)
        OR
        -- La nueva reserva engloba una existente
        (p_hora <= hora AND hora_fin >= (hora + (duracion_minutos || ' minutes')::INTERVAL)::TIME)
    );
    
    RETURN conflictos = 0;
END;
$$ LANGUAGE plpgsql;

-- FUNCIÓN PARA OBTENER MESAS DISPONIBLES
CREATE OR REPLACE FUNCTION obtener_mesas_disponibles(
    p_fecha DATE,
    p_hora TIME,
    p_personas INTEGER,
    p_duracion_minutos INTEGER DEFAULT 120
) RETURNS TABLE(
    mesa_id UUID,
    numero INTEGER,
    capacidad INTEGER,
    ubicacion VARCHAR,
    caracteristicas TEXT[],
    disponible BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.id,
        m.numero,
        m.capacidad,
        m.ubicacion,
        m.caracteristicas,
        verificar_disponibilidad_mesa(m.id, p_fecha, p_hora, p_duracion_minutos) as disponible
    FROM sodita_mesas m
    WHERE m.activa = TRUE 
    AND m.capacidad >= p_personas
    ORDER BY 
        verificar_disponibilidad_mesa(m.id, p_fecha, p_hora, p_duracion_minutos) DESC,
        m.capacidad ASC,
        m.numero ASC;
END;
$$ LANGUAGE plpgsql;

-- FUNCIÓN PARA OBTENER HORARIOS DISPONIBLES
CREATE OR REPLACE FUNCTION obtener_horarios_disponibles(
    p_fecha DATE,
    p_personas INTEGER DEFAULT 2
) RETURNS TABLE(
    hora TIME,
    mesas_disponibles INTEGER,
    disponible BOOLEAN
) AS $$
DECLARE
    horario_inicio TIME;
    horario_fin TIME;
    dia_semana TEXT;
    config JSONB;
BEGIN
    -- Obtener día de la semana en español
    dia_semana := CASE EXTRACT(DOW FROM p_fecha)
        WHEN 0 THEN 'domingo'
        WHEN 1 THEN 'lunes'
        WHEN 2 THEN 'martes'
        WHEN 3 THEN 'miercoles'
        WHEN 4 THEN 'jueves'
        WHEN 5 THEN 'viernes'
        WHEN 6 THEN 'sabado'
    END;
    
    -- Obtener configuración de horarios
    SELECT valor INTO config 
    FROM sodita_configuracion 
    WHERE clave = 'info_restaurante';
    
    -- Verificar si el restaurante está abierto ese día
    IF config->'horarios'->dia_semana IS NULL OR dia_semana = 'lunes' THEN
        RETURN; -- Cerrado los lunes
    END IF;
    
    horario_inicio := (config->'horarios'->dia_semana->>'inicio')::TIME;
    horario_fin := (config->'horarios'->dia_semana->>'fin')::TIME;
    
    -- Generar horarios cada 30 minutos
    FOR hora IN 
        SELECT generate_series(
            horario_inicio,
            horario_fin - INTERVAL '30 minutes',
            INTERVAL '30 minutes'
        )::TIME
    LOOP
        -- Contar mesas disponibles para este horario
        SELECT COUNT(*) INTO mesas_disponibles
        FROM obtener_mesas_disponibles(p_fecha, hora, p_personas)
        WHERE disponible = TRUE;
        
        disponible := mesas_disponibles > 0;
        
        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- VISTA PARA DASHBOARD DEL RESTAURANTE
CREATE VIEW sodita_dashboard_hoy AS
SELECT 
    CURRENT_DATE as fecha,
    COUNT(*) as total_reservas,
    SUM(personas) as total_comensales,
    COUNT(CASE WHEN estado = 'confirmada' THEN 1 END) as reservas_pendientes,
    COUNT(CASE WHEN estado = 'en_mesa' THEN 1 END) as mesas_ocupadas,
    COUNT(CASE WHEN estado = 'completada' THEN 1 END) as reservas_completadas,
    COUNT(CASE WHEN estado = 'no_show' THEN 1 END) as no_shows,
    ROUND(AVG(personas), 1) as promedio_personas_por_mesa
FROM sodita_reservas 
WHERE fecha = CURRENT_DATE;

-- VISTA PARA OCUPACIÓN POR MESA
CREATE VIEW sodita_ocupacion_mesas AS
SELECT 
    m.numero,
    m.ubicacion,
    m.capacidad,
    r.fecha,
    r.hora,
    r.estado,
    r.nombre as cliente,
    r.personas,
    r.codigo_confirmacion
FROM sodita_mesas m
LEFT JOIN sodita_reservas r ON m.id = r.mesa_id 
    AND r.fecha >= CURRENT_DATE 
    AND r.estado IN ('confirmada', 'en_mesa', 'completada')
ORDER BY m.numero, r.fecha, r.hora;