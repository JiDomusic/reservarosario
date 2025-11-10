-- SCRIPT PARA VACIAR COMPLETAMENTE LAS RESERVAS DE SODITA
-- ⚠️ CUIDADO: Esto borra TODAS las reservas
-- Ejecutar en el panel de Supabase: https://supabase.com/dashboard/project/weurjculqnxvtmbqltjo

-- 💾 BACKUP: Ver todas las reservas antes de borrar
SELECT 
    'BACKUP - Total reservas antes de limpiar: ' || COUNT(*) as info
FROM sodita_reservas;

-- 📊 Estadísticas antes de limpiar
SELECT 
    estado,
    COUNT(*) as cantidad
FROM sodita_reservas 
GROUP BY estado
ORDER BY estado;

-- 🗑️ BORRAR TODAS LAS RESERVAS
-- (Descomenta la siguiente línea cuando estés seguro)
-- DELETE FROM sodita_reservas;

-- ✅ Verificar que se borró todo
SELECT COUNT(*) as reservas_restantes FROM sodita_reservas;

-- 📝 Nota: Las mesas (sodita_mesas) NO se tocan, solo las reservas