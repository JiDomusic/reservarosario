-- ============================================
-- ELIMINAR TABLAS DE SUSCRIPCIÓN
-- ============================================

-- Eliminar tablas de suscripción y pagos
DROP TABLE IF EXISTS restaurant_payments CASCADE;
DROP TABLE IF EXISTS restaurant_subscriptions CASCADE;

-- Eliminar funciones relacionadas
DROP FUNCTION IF EXISTS activate_restaurant_subscription(UUID);
DROP FUNCTION IF EXISTS check_restaurant_subscription_status(UUID);
DROP FUNCTION IF EXISTS get_subscription_status();

-- Verificar que se eliminaron
SELECT 'Subscription tables removed successfully' as status;