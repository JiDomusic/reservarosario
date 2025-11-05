-- ============================================
-- ARREGLAR LIBERACIÓN AUTOMÁTICA PARA TODOS LOS RESTAURANTES
-- ============================================

-- 1. VERIFICAR Y ARREGLAR SODITA
-- Agregar updated_at si no existe
ALTER TABLE sodita_reservas 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Actualizar registros existentes de Sodita
UPDATE sodita_reservas 
SET updated_at = creado_en 
WHERE updated_at IS NULL;

-- 2. VERIFICAR Y ARREGLAR MULTI-RESTAURANTES
-- Agregar updated_at si no existe
ALTER TABLE restaurant_reservations 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Actualizar registros existentes de otros restaurantes
UPDATE restaurant_reservations 
SET updated_at = created_at 
WHERE updated_at IS NULL;

-- 3. VERIFICAR QUE LOS TRIGGERS EXISTEN
-- Para Sodita (ya existe según el error)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'update_sodita_reservas_updated_at'
    ) THEN
        CREATE TRIGGER update_sodita_reservas_updated_at 
            BEFORE UPDATE ON sodita_reservas 
            FOR EACH ROW 
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- Para Multi-restaurantes
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

-- 4. VERIFICAR COLUMNAS Y TRIGGERS CREADOS
SELECT 
    'SODITA' as sistema,
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'sodita_reservas' 
AND column_name IN ('updated_at', 'creado_en', 'comentarios')

UNION ALL

SELECT 
    'MULTI-RESTAURANT' as sistema,
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'restaurant_reservations' 
AND column_name IN ('updated_at', 'created_at', 'notes')

ORDER BY sistema, column_name;

-- 5. VERIFICAR TRIGGERS
SELECT 
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation
FROM information_schema.triggers 
WHERE trigger_name LIKE '%updated_at%'
AND event_object_table IN ('sodita_reservas', 'restaurant_reservations');