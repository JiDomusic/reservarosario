-- MIGRACIÓN SODITA: AGREGAR FUNCIONALIDADES WOKI A SCHEMA EXISTENTE
-- Este script mantiene tus datos actuales y agrega las nuevas funcionalidades

-- ================================
-- 1. ACTUALIZAR TABLA DE RESERVAS EXISTENTE
-- ================================

-- Agregar nuevas columnas a la tabla existente
ALTER TABLE sodita_reservas ADD COLUMN IF NOT EXISTS usuario_id UUID;
ALTER TABLE sodita_reservas ADD COLUMN IF NOT EXISTS tipo_reserva VARCHAR(20) DEFAULT 'normal' 
    CHECK (tipo_reserva IN ('normal', 'mesaya', 'cola_virtual'));
ALTER TABLE sodita_reservas ADD COLUMN IF NOT EXISTS prioridad VARCHAR(20) DEFAULT 'regular' 
    CHECK (prioridad IN ('vip', 'premium', 'regular', 'bajo', 'nuevo'));
ALTER TABLE sodita_reservas ADD COLUMN IF NOT EXISTS expira_confirmacion TIMESTAMP WITH TIME ZONE;

-- Agregar email opcional a reservas
ALTER TABLE sodita_reservas ADD COLUMN IF NOT EXISTS email VARCHAR(100);

-- ================================
-- 2. CREAR NUEVAS TABLAS WOKI
-- ================================

-- Tabla de usuarios con sistema de reputación
CREATE TABLE IF NOT EXISTS sodita_usuarios (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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

-- Tabla de cola virtual
CREATE TABLE IF NOT EXISTS sodita_cola_virtual (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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

-- Tabla de notificaciones
CREATE TABLE IF NOT EXISTS sodita_notificaciones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  usuario_id VARCHAR(50) NOT NULL, -- Puede ser UUID de usuario o 'admin'
  tipo VARCHAR(50) NOT NULL CHECK (tipo IN ('mesa_disponible', 'recordatorio_reserva', 'confirmacion_requerida', 'mesa_liberada', 'tiempo_agotandose', 'review_request')),
  titulo VARCHAR(200) NOT NULL,
  mensaje TEXT NOT NULL,
  data JSONB,
  leida BOOLEAN DEFAULT false,
  fecha TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla de reviews verificados
CREATE TABLE IF NOT EXISTS sodita_reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  usuario_id UUID NOT NULL REFERENCES sodita_usuarios(id),
  reserva_id UUID NOT NULL REFERENCES sodita_reservas(id),
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comentario TEXT,
  verificado BOOLEAN DEFAULT true,
  fecha TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(usuario_id, reserva_id)
);

-- Tabla de tareas programadas
CREATE TABLE IF NOT EXISTS sodita_tareas_programadas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tipo VARCHAR(50) NOT NULL CHECK (tipo IN ('recordatorio_reserva', 'alerta_tiempo_agotandose', 'solicitar_review', 'liberar_mesa')),
  usuario_id UUID REFERENCES sodita_usuarios(id),
  fecha_ejecucion TIMESTAMP WITH TIME ZONE NOT NULL,
  data JSONB,
  estado VARCHAR(20) DEFAULT 'programada' CHECK (estado IN ('programada', 'ejecutada', 'cancelada')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  executed_at TIMESTAMP WITH TIME ZONE
);

-- Tabla de métricas históricas
CREATE TABLE IF NOT EXISTS sodita_metricas_diarias (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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

-- ================================
-- 3. ACTUALIZAR MESAS PARA LAYOUT WOKI
-- ================================

-- LAYOUT SODITA: 10 mesas exactas
-- Mesa 1: Living 
UPDATE sodita_mesas SET ubicacion = 'Living', capacidad = 12 WHERE numero = 1;

-- Mesas 2-5: Mesas Barra (4 mesas con sillas altas tipo barra)
UPDATE sodita_mesas SET ubicacion = 'Mesas Barra', capacidad = 4 WHERE numero IN (2, 3, 4, 5);

-- Mesas 6-10: Mesas Bajas (5 mesas normales con sillas bajas)  
UPDATE sodita_mesas SET ubicacion = 'Mesas Bajas', capacidad = 4 WHERE numero IN (6, 7, 8, 9, 10);

-- Crear mesas adicionales si no existen (hasta 10 total)
INSERT INTO sodita_mesas (numero, ubicacion, capacidad, activa) VALUES
(2, 'Mesas Barra', 4, true),
(3, 'Mesas Barra', 4, true), 
(4, 'Mesas Barra', 4, true),
(5, 'Mesas Barra', 4, true),
(6, 'Mesas Bajas', 4, true),
(7, 'Mesas Bajas', 4, true),
(8, 'Mesas Bajas', 4, true),
(9, 'Mesas Bajas', 4, true),
(10, 'Mesas Bajas', 4, true)
ON CONFLICT (numero) DO UPDATE SET
    ubicacion = EXCLUDED.ubicacion,
    capacidad = EXCLUDED.capacidad,
    activa = EXCLUDED.activa;

-- ================================
-- 4. CREAR ÍNDICES NUEVOS
-- ================================

-- Usuarios
CREATE INDEX IF NOT EXISTS idx_usuarios_telefono ON sodita_usuarios(telefono);
CREATE INDEX IF NOT EXISTS idx_usuarios_reputacion ON sodita_usuarios(reputacion);
CREATE INDEX IF NOT EXISTS idx_usuarios_verificado ON sodita_usuarios(verificado);

-- Reservas (nuevos campos)
CREATE INDEX IF NOT EXISTS idx_reservas_usuario_id ON sodita_reservas(usuario_id);
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

-- ================================
-- 5. AGREGAR REFERENCIA FK CUANDO SEA POSIBLE
-- ================================

-- Solo agregar FK si no existe
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'sodita_reservas_usuario_id_fkey'
    ) THEN
        ALTER TABLE sodita_reservas 
        ADD CONSTRAINT sodita_reservas_usuario_id_fkey 
        FOREIGN KEY (usuario_id) REFERENCES sodita_usuarios(id);
    END IF;
END $$;

-- ================================
-- 6. CREAR TRIGGERS PARA NUEVAS TABLAS
-- ================================

-- Función para updated_at (si no existe)
CREATE OR REPLACE FUNCTION update_updated_at_column_woki()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para updated_at
CREATE TRIGGER update_usuarios_updated_at BEFORE UPDATE ON sodita_usuarios
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column_woki();

CREATE TRIGGER update_cola_updated_at BEFORE UPDATE ON sodita_cola_virtual
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column_woki();

-- ================================
-- 7. CONFIGURAR RLS PARA NUEVAS TABLAS
-- ================================

-- Habilitar RLS
ALTER TABLE sodita_usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE sodita_cola_virtual ENABLE ROW LEVEL SECURITY;
ALTER TABLE sodita_notificaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE sodita_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE sodita_tareas_programadas ENABLE ROW LEVEL SECURITY;
ALTER TABLE sodita_metricas_diarias ENABLE ROW LEVEL SECURITY;

-- Políticas permisivas para desarrollo (ajustar en producción)
CREATE POLICY "Enable all access for users" ON sodita_usuarios FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for queue" ON sodita_cola_virtual FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for notifications" ON sodita_notificaciones FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for reviews" ON sodita_reviews FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for tasks" ON sodita_tareas_programadas FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Enable all access for metrics" ON sodita_metricas_diarias FOR ALL USING (true) WITH CHECK (true);

-- ================================
-- 8. CREAR FUNCIONES PERSONALIZADAS
-- ================================

-- Función para calcular métricas diarias
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

-- ================================
-- 9. INSERTAR USUARIO ADMIN DE EJEMPLO
-- ================================

-- Usuario administrador
INSERT INTO sodita_usuarios (nombre, telefono, email, reputacion, verificado) VALUES
('Admin SODITA', 'equiz.rec@gmail.com', 'equiz.rec@gmail.com', 100, true)
ON CONFLICT (telefono) DO NOTHING;

-- ================================
-- 10. VERIFICACIÓN FINAL
-- ================================

-- Mostrar resumen de tablas creadas
SELECT 
    schemaname,
    tablename,
    hasindexes,
    hasrules,
    hastriggers
FROM pg_tables 
WHERE tablename LIKE 'sodita_%' 
ORDER BY tablename;

-- Mostrar usuarios creados
SELECT COUNT(*) as total_usuarios FROM sodita_usuarios;

-- Mostrar reservas existentes (conservadas)
SELECT COUNT(*) as reservas_existentes FROM sodita_reservas;

-- Mostrar nuevas columnas en reservas
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'sodita_reservas' 
AND column_name IN ('usuario_id', 'tipo_reserva', 'prioridad', 'email')
ORDER BY column_name;

COMMENT ON TABLE sodita_usuarios IS 'Sistema de usuarios con validación y reputación estilo Woki';
COMMENT ON TABLE sodita_cola_virtual IS 'Cola virtual para MesaYa! y gestión de espera inteligente';
COMMENT ON TABLE sodita_notificaciones IS 'Sistema de notificaciones push inteligentes';
COMMENT ON TABLE sodita_reviews IS 'Reviews verificados solo de usuarios que comieron';
COMMENT ON TABLE sodita_tareas_programadas IS 'Sistema de tareas automáticas y recordatorios';
COMMENT ON TABLE sodita_metricas_diarias IS 'Métricas históricas para analytics avanzados';

-- ================================
-- ¡MIGRACIÓN COMPLETADA!
-- ================================

SELECT 'MIGRACIÓN SODITA → WOKI COMPLETADA EXITOSAMENTE!' as resultado;