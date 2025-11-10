-- SCRIPT PARA LIMPIAR RESERVAS ANTIGUAS DE SODITA
-- Ejecutar en el panel de Supabase: https://supabase.com/dashboard/project/weurjculqnxvtmbqltjo

-- 🗑️ OPCIÓN 1: Borrar reservas más antiguas que 30 días
-- (Mantiene últimas 4 semanas para estadísticas)
DELETE FROM sodita_reservas 
WHERE fecha < CURRENT_DATE - INTERVAL '30 days';

-- 📊 Ver cuántas reservas quedan después de limpiar
SELECT 
    estado,
    COUNT(*) as cantidad,
    MIN(fecha) as fecha_mas_antigua,
    MAX(fecha) as fecha_mas_reciente
FROM sodita_reservas 
GROUP BY estado
ORDER BY estado;

-- 💾 VERIFICAR ANTES DE BORRAR: Ver qué se va a eliminar
-- (Descomenta estas líneas para ver qué reservas se borrarían)
/*
SELECT 
    fecha, 
    nombre, 
    estado, 
    sodita_mesas.numero as mesa
FROM sodita_reservas 
LEFT JOIN sodita_mesas ON sodita_reservas.mesa_id = sodita_mesas.id
WHERE fecha < CURRENT_DATE - INTERVAL '30 days'
ORDER BY fecha DESC;
*/