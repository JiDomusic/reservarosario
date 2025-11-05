-- Agregar campo updated_at a sodita_reservas si no existe
ALTER TABLE sodita_reservas 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Crear trigger para actualizar updated_at automáticamente
DROP TRIGGER IF EXISTS update_sodita_reservas_updated_at ON sodita_reservas;

CREATE TRIGGER update_sodita_reservas_updated_at 
    BEFORE UPDATE ON sodita_reservas 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Actualizar registros existentes
UPDATE sodita_reservas 
SET updated_at = creado_en 
WHERE updated_at IS NULL;

-- Verificar estructura
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'sodita_reservas' 
AND column_name IN ('updated_at', 'creado_en');