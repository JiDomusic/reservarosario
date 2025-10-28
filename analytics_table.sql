-- TABLA PARA ANALYTICS GRATUITOS - SODITA
-- Ejecutar en Supabase SQL Editor

CREATE TABLE IF NOT EXISTS sodita_analytics_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type VARCHAR(100) NOT NULL,
  event_data JSONB,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  platform VARCHAR(20) DEFAULT 'mobile', -- 'web', 'mobile', 'admin'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_analytics_event_type ON sodita_analytics_events(event_type);
CREATE INDEX IF NOT EXISTS idx_analytics_timestamp ON sodita_analytics_events(timestamp);
CREATE INDEX IF NOT EXISTS idx_analytics_platform ON sodita_analytics_events(platform);
CREATE INDEX IF NOT EXISTS idx_analytics_date ON sodita_analytics_events(DATE(timestamp));

-- RLS Policy
ALTER TABLE sodita_analytics_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable insert access for all users" ON sodita_analytics_events FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable read access for all users" ON sodita_analytics_events FOR SELECT USING (true);

-- Función para obtener resumen diario
CREATE OR REPLACE FUNCTION get_daily_analytics_summary(fecha_param DATE DEFAULT CURRENT_DATE)
RETURNS TABLE(
  event_type TEXT,
  event_count BIGINT,
  platform_breakdown JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ae.event_type::TEXT,
    COUNT(*)::BIGINT as event_count,
    jsonb_object_agg(ae.platform, platform_count.count) as platform_breakdown
  FROM sodita_analytics_events ae
  LEFT JOIN (
    SELECT 
      event_type, 
      platform, 
      COUNT(*) as count
    FROM sodita_analytics_events 
    WHERE DATE(timestamp) = fecha_param
    GROUP BY event_type, platform
  ) platform_count ON ae.event_type = platform_count.event_type
  WHERE DATE(ae.timestamp) = fecha_param
  GROUP BY ae.event_type
  ORDER BY event_count DESC;
END;
$$ LANGUAGE plpgsql;

-- Comentarios
COMMENT ON TABLE sodita_analytics_events IS 'Eventos de analytics gratuitos para SODITA';
COMMENT ON FUNCTION get_daily_analytics_summary IS 'Resumen diario de eventos de analytics';