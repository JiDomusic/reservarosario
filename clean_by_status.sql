-- SCRIPT PARA LIMPIAR RESERVAS POR ESTADO EN SODITA
-- Útil para mantener algunas reservas y borrar otras
-- Ejecutar en el panel de Supabase: https://supabase.com/dashboard/project/weurjculqnxvtmbqltjo

-- 📊 Ver estadísticas actuales
SELECT 
    estado,
    COUNT(*) as cantidad,
    MIN(fecha) as desde,
    MAX(fecha) as hasta
FROM sodita_reservas 
GROUP BY estado
ORDER BY 
    CASE estado 
        WHEN 'confirmada' THEN 1
        WHEN 'en_mesa' THEN 2  
        WHEN 'completada' THEN 3
        WHEN 'no_show' THEN 4
        WHEN 'cancelada' THEN 5
        WHEN 'expirada' THEN 6
        ELSE 7
    END;

-- 🗑️ OPCIÓN 1: Borrar solo reservas completadas antiguas (más de 7 días)
-- DELETE FROM sodita_reservas 
-- WHERE estado = 'completada' AND fecha < CURRENT_DATE - INTERVAL '7 days';

-- 🗑️ OPCIÓN 2: Borrar no-shows y canceladas antiguas (más de 3 días)  
-- DELETE FROM sodita_reservas 
-- WHERE estado IN ('no_show', 'cancelada', 'expirada') 
-- AND fecha < CURRENT_DATE - INTERVAL '3 days';

-- 🗑️ OPCIÓN 3: Limpiar todo lo que no sea de hoy o futuro
-- (Mantiene solo reservas activas)
-- DELETE FROM sodita_reservas 
-- WHERE fecha < CURRENT_DATE 
-- AND estado NOT IN ('confirmada', 'en_mesa');

-- ✅ Verificar después de limpiar
SELECT 
    'Limpieza completada. Reservas restantes: ' || COUNT(*) as resultado
FROM sodita_reservas;