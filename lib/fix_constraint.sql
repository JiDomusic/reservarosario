-- CORREGIR RESTRICCIÓN DE CAPACIDAD EN MESAS  
-- SODITA: 1 Living + 4 Mesas Barra + 5 Mesas Bajas = 10 mesas total

-- 1. Eliminar la restricción actual
ALTER TABLE sodita_mesas DROP CONSTRAINT IF EXISTS sodita_mesas_capacidad_check;

-- 2. Crear nueva restricción que permita hasta 12 personas (para el Living)
ALTER TABLE sodita_mesas ADD CONSTRAINT sodita_mesas_capacidad_check 
    CHECK (capacidad BETWEEN 2 AND 12);

-- 3. Verificar que se aplicó correctamente
SELECT conname, pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'sodita_mesas'::regclass 
AND contype = 'c';

-- 4. Mostrar las mesas actuales
SELECT numero, capacidad, ubicacion FROM sodita_mesas ORDER BY numero;