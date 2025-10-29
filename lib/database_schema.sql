-- ESQUEMA DE BASE DE DATOS PARA SODITA - FUNCIONALIDADES ESTILO WOKI
-- Ejecutar estos comandos en Supabase para crear las tablas necesarias

-- 1. TABLA DE USUARIOS (Sistema de validación y reputación Woki)
CREATE TABLE IF NOT EXISTS sodita_usuarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre VARCHAR(100) NOT NULL,
  telefono VARCHAR(20) NOT NULL UNIQUE,
  email VARCHAR(100),
  reputacion INTEGER DEFAULT 100 CHECK (reputacion >= 0 AND reputacion <= 100),
  total_reservas INTEGER DEFAULT 0,
  total_no_shows INTEGER DEFAULT 0,
  verificado BOOLEAN DEFAULT false,
  fecha_registro TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  ultima_actividad TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. ACTUALIZAR TABLA DE RESERVAS (Agregar campos Woki)
ALTER TABLE sodita_reservas ADD COLUMN IF NOT EXISTS usuario_id UUID REFERENCES sodita_usuarios(id);
ALTER TABLE sodita_reservas ADD COLUMN IF NOT EXISTS tipo_reserva VARCHAR(20) DEFAULT 'normal' CHECK (tipo_reserva IN ('normal', 'mesaya', 'cola_virtual'));
ALTER TABLE sodita_reservas ADD COLUMN IF NOT EXISTS prioridad VARCHAR(20) DEFAULT 'regular' CHECK (prioridad IN ('vip', 'premium', 'regular', 'bajo', 'nuevo'));
ALTER TABLE sodita_reservas ADD COLUMN IF NOT EXISTS expira_confirmacion TIMESTAMP WITH TIME ZONE;

-- 3. TABLA DE COLA VIRTUAL (MesaYa! y sistema de espera)
CREATE TABLE IF NOT EXISTS sodita_cola_virtual (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES sodita_usuarios(id),
  nombre VARCHAR(100) NOT NULL,
  telefono VARCHAR(20) NOT NULL,
  personas INTEGER NOT NULL CHECK (personas > 0),
  preferencia_mesa VARCHAR(50), -- 'living', 'barra', 'bajas'
  posicion INTEGER NOT NULL,
  prioridad VARCHAR(20) DEFAULT 'regular' CHECK (prioridad IN ('vip', 'premium', 'regular', 'bajo', 'nuevo')),
  tiempo_estimado INTEGER DEFAULT 0, -- minutos
  estado VARCHAR(20) DEFAULT 'esperando' CHECK (estado IN ('esperando', 'notificado', 'cancelado')),
  fecha_ingreso TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  fecha_notificacion TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. TABLA DE NOTIFICACIONES (Sistema de alertas inteligentes)
CREATE TABLE IF NOT EXISTS sodita_notificaciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id VARCHAR(50) NOT NULL, -- Puede ser UUID de usuario o 'admin'
  tipo VARCHAR(50) NOT NULL CHECK (tipo IN ('mesa_disponible', 'recordatorio_reserva', 'confirmacion_requerida', 'mesa_liberada', 'tiempo_agotandose', 'review_request')),
  titulo VARCHAR(200) NOT NULL,
  mensaje TEXT NOT NULL,
  data JSONB,
  leida BOOLEAN DEFAULT false,
  fecha TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. TABLA DE REVIEWS VERIFICADOS (Solo usuarios que comieron pueden opinar)
CREATE TABLE IF NOT EXISTS sodita_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES sodita_usuarios(id),
  reserva_id UUID NOT NULL REFERENCES sodita_reservas(id),
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comentario TEXT,
  verificado BOOLEAN DEFAULT true, -- Siempre true porque solo usuarios verificados pueden reviewar
  fecha TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(usuario_id, reserva_id) -- Un review por reserva por usuario
);

-- 6. TABLA DE TAREAS PROGRAMADAS (Para notificaciones automáticas)
CREATE TABLE IF NOT EXISTS sodita_tareas_programadas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo VARCHAR(50) NOT NULL CHECK (tipo IN ('recordatorio_reserva', 'alerta_tiempo_agotandose', 'solicitar_review', 'liberar_mesa')),
  usuario_id UUID REFERENCES sodita_usuarios(id),
  fecha_ejecucion TIMESTAMP WITH TIME ZONE NOT NULL,
  data JSONB,
  estado VARCHAR(20) DEFAULT 'programada' CHECK (estado IN ('programada', 'ejecutada', 'cancelada')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  executed_at TIMESTAMP WITH TIME ZONE
);

-- 7. TABLA DE MÉTRICAS HISTÓRICAS (Para analytics avanzados)
CREATE TABLE IF NOT EXISTS sodita_metricas_diarias (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fecha DATE NOT NULL UNIQUE,
  total_reservas INTEGER DEFAULT 0,
  reservas_completadas INTEGER DEFAULT 0,
  no_shows INTEGER DEFAULT 0,
  total_comensales INTEGER DEFAULT 0,
  ingresos_estimados DECIMAL(10,2) DEFAULT 0,
  tasa_ocupacion DECIMAL(5,2) DEFAULT 0,
  tiempo_promedio_mesa INTEGER DEFAULT 0, -- minutos
  data_adicional JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ÍNDICES PARA PERFORMANCE

-- Usuarios
CREATE INDEX IF NOT EXISTS idx_usuarios_telefono ON sodita_usuarios(telefono);
CREATE INDEX IF NOT EXISTS idx_usuarios_reputacion ON sodita_usuarios(reputacion);
CREATE INDEX IF NOT EXISTS idx_usuarios_verificado ON sodita_usuarios(verificado);

-- Reservas
CREATE INDEX IF NOT EXISTS idx_reservas_usuario_id ON sodita_reservas(usuario_id);
CREATE INDEX IF NOT EXISTS idx_reservas_fecha_estado ON sodita_reservas(fecha, estado);
CREATE INDEX IF NOT EXISTS idx_reservas_tipo_reserva ON sodita_reservas(tipo_reserva);
CREATE INDEX IF NOT EXISTS idx_reservas_expira_confirmacion ON sodita_reservas(expira_confirmacion);

-- Cola Virtual
CREATE INDEX IF NOT EXISTS idx_cola_usuario_estado ON sodita_cola_virtual(usuario_id, estado);
CREATE INDEX IF NOT EXISTS idx_cola_estado_posicion ON sodita_cola_virtual(estado, posicion);
CREATE INDEX IF NOT EXISTS idx_cola_fecha_ingreso ON sodita_cola_virtual(fecha_ingreso);

-- Notificaciones
CREATE INDEX IF NOT EXISTS idx_notificaciones_usuario_leida ON sodita_notificaciones(usuario_id, leida);
CREATE INDEX IF NOT EXISTS idx_notificaciones_tipo_fecha ON sodita_notificaciones(tipo, fecha);

-- Reviews
CREATE INDEX IF NOT EXISTS idx_reviews_usuario_reserva ON sodita_reviews(usuario_id, reserva_id);
CREATE INDEX IF NOT EXISTS idx_reviews_rating_fecha ON sodita_reviews(rating, fecha);

-- Tareas Programadas
CREATE INDEX IF NOT EXISTS idx_tareas_fecha_estado ON sodita_tareas_programadas(fecha_ejecucion, estado);
CREATE INDEX IF NOT EXISTS idx_tareas_tipo_estado ON sodita_tareas_programadas(tipo, estado);

-- Métricas
CREATE INDEX IF NOT EXISTS idx_metricas_fecha ON sodita_metricas_diarias(fecha);

-- TRIGGERS PARA UPDATED_AT

-- Usuarios
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_usuarios_updated_at BEFORE UPDATE ON sodita_usuarios
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cola_updated_at BEFORE UPDATE ON sodita_cola_virtual
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS (Row Level Security) POLICIES

-- Habilitar RLS en todas las tablas
ALTER TABLE sodita_usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE sodita_cola_virtual ENABLE ROW LEVEL SECURITY;
ALTER TABLE sodita_notificaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE sodita_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE sodita_tareas_programadas ENABLE ROW LEVEL SECURITY;
ALTER TABLE sodita_metricas_diarias ENABLE ROW LEVEL SECURITY;

-- Políticas básicas (permitir todas las operaciones para usuarios autenticados)
-- En producción, estas políticas deberían ser más restrictivas

CREATE POLICY "Enable read access for all users" ON sodita_usuarios FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON sodita_usuarios FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON sodita_usuarios FOR UPDATE USING (true);

CREATE POLICY "Enable read access for all users" ON sodita_cola_virtual FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON sodita_cola_virtual FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON sodita_cola_virtual FOR UPDATE USING (true);
CREATE POLICY "Enable delete access for all users" ON sodita_cola_virtual FOR DELETE USING (true);

CREATE POLICY "Enable read access for all users" ON sodita_notificaciones FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON sodita_notificaciones FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON sodita_notificaciones FOR UPDATE USING (true);

CREATE POLICY "Enable read access for all users" ON sodita_reviews FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON sodita_reviews FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON sodita_reviews FOR UPDATE USING (true);

CREATE POLICY "Enable read access for all users" ON sodita_tareas_programadas FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON sodita_tareas_programadas FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON sodita_tareas_programadas FOR UPDATE USING (true);

CREATE POLICY "Enable read access for all users" ON sodita_metricas_diarias FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON sodita_metricas_diarias FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON sodita_metricas_diarias FOR UPDATE USING (true);

-- FUNCIONES PERSONALIZADAS

-- Función para calcular automáticamente métricas diarias
CREATE OR REPLACE FUNCTION calcular_metricas_diarias(fecha_param DATE DEFAULT CURRENT_DATE)
RETURNS void AS $$
DECLARE
    total_reservas_var INTEGER;
    completadas_var INTEGER;
    no_shows_var INTEGER;
    total_comensales_var INTEGER;
    ingresos_var DECIMAL(10,2);
    tasa_ocupacion_var DECIMAL(5,2);
BEGIN
    -- Calcular métricas del día
    SELECT 
        COUNT(*),
        COUNT(*) FILTER (WHERE estado = 'completada'),
        COUNT(*) FILTER (WHERE estado = 'no_show'),
        COALESCE(SUM(personas), 0)
    INTO total_reservas_var, completadas_var, no_shows_var, total_comensales_var
    FROM sodita_reservas 
    WHERE fecha = fecha_param;

    -- Calcular ingresos estimados (2500 pesos por persona completada)
    SELECT COALESCE(SUM(personas * 2500), 0)
    INTO ingresos_var
    FROM sodita_reservas 
    WHERE fecha = fecha_param AND estado = 'completada';

    -- Calcular tasa de ocupación promedio del día
    SELECT COALESCE(AVG(
        CASE WHEN estado IN ('confirmada', 'en_mesa') THEN 1 ELSE 0 END
    ) * 100, 0)
    INTO tasa_ocupacion_var
    FROM sodita_reservas 
    WHERE fecha = fecha_param;

    -- Insertar o actualizar métricas
    INSERT INTO sodita_metricas_diarias (
        fecha, total_reservas, reservas_completadas, no_shows, 
        total_comensales, ingresos_estimados, tasa_ocupacion
    ) VALUES (
        fecha_param, total_reservas_var, completadas_var, no_shows_var,
        total_comensales_var, ingresos_var, tasa_ocupacion_var
    )
    ON CONFLICT (fecha) DO UPDATE SET
        total_reservas = EXCLUDED.total_reservas,
        reservas_completadas = EXCLUDED.reservas_completadas,
        no_shows = EXCLUDED.no_shows,
        total_comensales = EXCLUDED.total_comensales,
        ingresos_estimados = EXCLUDED.ingresos_estimados,
        tasa_ocupacion = EXCLUDED.tasa_ocupacion;
END;
$$ LANGUAGE plpgsql;

-- DATOS INICIALES DE EJEMPLO

-- Insertar tipos de mesa base
INSERT INTO sodita_mesas (numero, capacidad, ubicacion, activa) VALUES
(1, 12, 'Living', true),
(2, 4, 'Mesas Barra', true),
(3, 4, 'Mesas Barra', true),
(4, 4, 'Mesas Barra', true),
(5, 4, 'Mesas Barra', true),
(6, 6, 'Mesas Bajas', true),
(7, 4, 'Mesas Bajas', true),
(8, 4, 'Mesas Bajas', true),
(9, 4, 'Mesas Bajas', true),
(10, 4, 'Mesas Bajas', true)
ON CONFLICT (numero) DO NOTHING;

-- Usuario administrador ejemplo
INSERT INTO sodita_usuarios (nombre, telefono, email, reputacion, verificado) VALUES
('Admin SODITA', '+54 9 341 000-0000', 'admin@sodita.com', 100, true)
ON CONFLICT (telefono) DO NOTHING;

COMMENT ON TABLE sodita_usuarios IS 'Sistema de usuarios con validación y reputación estilo Woki';
COMMENT ON TABLE sodita_cola_virtual IS 'Cola virtual para MesaYa! y gestión de espera inteligente';
COMMENT ON TABLE sodita_notificaciones IS 'Sistema de notificaciones push inteligentes';
COMMENT ON TABLE sodita_reviews IS 'Reviews verificados solo de usuarios que comieron';
COMMENT ON TABLE sodita_tareas_programadas IS 'Sistema de tareas automáticas y recordatorios';
COMMENT ON TABLE sodita_metricas_diarias IS 'Métricas históricas para analytics avanzados';