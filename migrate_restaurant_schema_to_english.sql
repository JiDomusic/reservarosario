-- ============================================
-- MIGRAR SCHEMA DE MULTI-RESTAURANTES A INGLÉS
-- ============================================

-- 1. PRIMERO VERIFICAR ESTRUCTURA ACTUAL
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'restaurant_reservations'
ORDER BY ordinal_position;

-- 2. CREAR NUEVAS COLUMNAS EN INGLÉS SI NO EXISTEN
ALTER TABLE restaurant_reservations 
ADD COLUMN IF NOT EXISTS confirmation_code VARCHAR(50);

-- 3. AJUSTAR NOMBRES DE COLUMNAS SI ES NECESARIO
-- Nota: Si el schema ya está en inglés, estos comandos no harán nada

-- 4. ACTUALIZAR DATOS EXISTENTES
UPDATE restaurant_reservations 
SET confirmation_code = 'RES' || LPAD((EXTRACT(EPOCH FROM created_at)::BIGINT % 10000)::TEXT, 4, '0')
WHERE confirmation_code IS NULL;

-- 5. VERIFICAR TABLA DE MESAS
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'restaurant_tables'
ORDER BY ordinal_position;

-- 6. CREAR ÍNDICES IMPORTANTES
CREATE INDEX IF NOT EXISTS idx_restaurant_reservations_status ON restaurant_reservations(status);
CREATE INDEX IF NOT EXISTS idx_restaurant_reservations_table_id ON restaurant_reservations(table_id);
CREATE INDEX IF NOT EXISTS idx_restaurant_reservations_date_time ON restaurant_reservations(reservation_date, reservation_time);
CREATE INDEX IF NOT EXISTS idx_restaurant_reservations_confirmation ON restaurant_reservations(confirmation_code);

-- 7. VERIFICAR TRIGGERS
SELECT 
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation
FROM information_schema.triggers 
WHERE event_object_table = 'restaurant_reservations';

-- 8. ASEGURAR TRIGGER DE updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 9. CREAR TRIGGER SI NO EXISTE
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'update_restaurant_reservations_updated_at'
    ) THEN
        CREATE TRIGGER update_restaurant_reservations_updated_at 
            BEFORE UPDATE ON restaurant_reservations 
            FOR EACH ROW 
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- 10. FUNCIÓN PARA PROCESAR RESERVAS EXPIRADAS DE UN RESTAURANTE
CREATE OR REPLACE FUNCTION process_expired_reservations_for_restaurant(restaurant_uuid UUID)
RETURNS TABLE(
    reservation_id UUID,
    customer_name VARCHAR,
    table_number INTEGER,
    reservation_time TIME,
    was_expired BOOLEAN
) AS $$
DECLARE
    expired_count INTEGER := 0;
BEGIN
    -- Liberar reservas expiradas (más de 15 minutos)
    UPDATE restaurant_reservations 
    SET 
        status = 'expired',
        notes = 'Liberada automáticamente - Cliente no se presentó en 15 minutos',
        updated_at = NOW()
    WHERE restaurant_id = restaurant_uuid
    AND status = 'confirmed'
    AND reservation_date = CURRENT_DATE
    AND (reservation_time + INTERVAL '15 minutes') < CURRENT_TIME;
    
    GET DIAGNOSTICS expired_count = ROW_COUNT;
    
    -- Retornar información de reservas procesadas
    RETURN QUERY
    SELECT 
        rr.id as reservation_id,
        rr.customer_name,
        rt.table_number,
        rr.reservation_time,
        true as was_expired
    FROM restaurant_reservations rr
    JOIN restaurant_tables rt ON rr.table_id = rt.id
    WHERE rr.restaurant_id = restaurant_uuid
    AND rr.status = 'expired'
    AND rr.reservation_date = CURRENT_DATE
    AND rr.updated_at > (NOW() - INTERVAL '1 minute');
    
    RAISE NOTICE 'Processed % expired reservations for restaurant %', expired_count, restaurant_uuid;
END;
$$ LANGUAGE plpgsql;

-- 11. FUNCIÓN PARA VERIFICAR ESTADO DEL RESTAURANTE
CREATE OR REPLACE FUNCTION get_restaurant_status_summary(restaurant_uuid UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'restaurant_id', restaurant_uuid,
        'total_tables', COUNT(DISTINCT rt.id),
        'active_tables', COUNT(DISTINCT CASE WHEN rt.is_available THEN rt.id END),
        'total_reservations_today', COUNT(DISTINCT CASE WHEN rr.reservation_date = CURRENT_DATE THEN rr.id END),
        'confirmed_reservations', COUNT(DISTINCT CASE WHEN rr.status = 'confirmed' AND rr.reservation_date = CURRENT_DATE THEN rr.id END),
        'seated_reservations', COUNT(DISTINCT CASE WHEN rr.status = 'seated' AND rr.reservation_date = CURRENT_DATE THEN rr.id END),
        'expired_reservations', COUNT(DISTINCT CASE WHEN rr.status = 'expired' AND rr.reservation_date = CURRENT_DATE THEN rr.id END),
        'cancelled_reservations', COUNT(DISTINCT CASE WHEN rr.status = 'cancelled' AND rr.reservation_date = CURRENT_DATE THEN rr.id END)
    ) INTO result
    FROM restaurants r
    LEFT JOIN restaurant_tables rt ON r.id = rt.restaurant_id
    LEFT JOIN restaurant_reservations rr ON r.id = rr.restaurant_id
    WHERE r.id = restaurant_uuid
    GROUP BY r.id;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 12. COMENTARIOS FINALES
COMMENT ON FUNCTION process_expired_reservations_for_restaurant IS 'Procesa y libera reservas expiradas para un restaurante específico';
COMMENT ON FUNCTION get_restaurant_status_summary IS 'Obtiene resumen del estado actual de un restaurante';

SELECT 'Migration script completed successfully' as status;