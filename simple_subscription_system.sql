-- ============================================
-- SISTEMA DE SUSCRIPCIÓN SIMPLE PARA TODOS LOS RESTAURANTES
-- ============================================

-- 1. AGREGAR CAMPOS DE SUSCRIPCIÓN A LA TABLA RESTAURANTS
ALTER TABLE restaurants 
ADD COLUMN IF NOT EXISTS subscription_status VARCHAR(20) DEFAULT 'pending_payment';

ALTER TABLE restaurants 
ADD COLUMN IF NOT EXISTS monthly_fee DECIMAL(10,2) DEFAULT 50000.00;

ALTER TABLE restaurants 
ADD COLUMN IF NOT EXISTS next_payment_date DATE DEFAULT (CURRENT_DATE + INTERVAL '30 days');

ALTER TABLE restaurants 
ADD COLUMN IF NOT EXISTS payment_method VARCHAR(50) DEFAULT 'bank_transfer';

ALTER TABLE restaurants 
ADD COLUMN IF NOT EXISTS subscription_notes TEXT;

-- 2. CREAR TABLA SIMPLE DE PAGOS
CREATE TABLE IF NOT EXISTS restaurant_payment_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'pending', -- pending, confirmed, rejected
    payment_method VARCHAR(50) DEFAULT 'bank_transfer',
    transaction_reference TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. FUNCIÓN PARA ACTIVAR SUSCRIPCIÓN DE UN RESTAURANTE
CREATE OR REPLACE FUNCTION activate_restaurant(restaurant_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Activar el restaurante y su suscripción
    UPDATE restaurants 
    SET 
        is_active = true,
        subscription_status = 'active',
        next_payment_date = CURRENT_DATE + INTERVAL '1 month'
    WHERE id = restaurant_uuid;
    
    -- Registrar el pago
    INSERT INTO restaurant_payment_history (restaurant_id, amount, status, notes)
    VALUES (restaurant_uuid, 50000.00, 'confirmed', 'Activación inicial confirmada');
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 4. FUNCIÓN PARA SUSPENDER RESTAURANTE POR FALTA DE PAGO
CREATE OR REPLACE FUNCTION suspend_restaurant(restaurant_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE restaurants 
    SET 
        is_active = false,
        subscription_status = 'suspended'
    WHERE id = restaurant_uuid;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 5. FUNCIÓN PARA VER ESTADO DE TODAS LAS SUSCRIPCIONES
CREATE OR REPLACE FUNCTION get_all_subscriptions()
RETURNS TABLE(
    restaurant_name TEXT,
    email TEXT,
    subscription_status TEXT,
    next_payment_date DATE,
    days_until_payment INTEGER,
    is_active BOOLEAN,
    monthly_fee DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.name::TEXT,
        r.email::TEXT,
        r.subscription_status::TEXT,
        r.next_payment_date,
        EXTRACT(days FROM (r.next_payment_date - CURRENT_DATE))::INTEGER,
        r.is_active,
        r.monthly_fee
    FROM restaurants r
    ORDER BY r.next_payment_date ASC;
END;
$$ LANGUAGE plpgsql;

-- 6. CONFIGURAR TODOS LOS RESTAURANTES EXISTENTES
UPDATE restaurants 
SET 
    subscription_status = CASE 
        WHEN is_active = true THEN 'active'
        ELSE 'pending_payment'
    END,
    monthly_fee = 50000.00,
    next_payment_date = CURRENT_DATE + INTERVAL '30 days',
    payment_method = 'bank_transfer'
WHERE subscription_status IS NULL;

-- 7. CREAR POLÍTICAS RLS PARA LA TABLA DE PAGOS
ALTER TABLE restaurant_payment_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Restaurant owners can view their payment history" ON restaurant_payment_history
    FOR SELECT USING (
        restaurant_id IN (
            SELECT id FROM restaurants WHERE auth_user_id = auth.uid()
        )
    );

-- 8. FUNCIÓN PARA VERIFICAR RESTAURANTES CON PAGOS VENCIDOS
CREATE OR REPLACE FUNCTION check_overdue_payments()
RETURNS TABLE(
    restaurant_name TEXT,
    email TEXT,
    days_overdue INTEGER,
    amount_due DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.name::TEXT,
        r.email::TEXT,
        EXTRACT(days FROM (CURRENT_DATE - r.next_payment_date))::INTEGER,
        r.monthly_fee
    FROM restaurants r
    WHERE r.subscription_status = 'active' 
    AND r.next_payment_date < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

-- 9. VERIFICAR INSTALACIÓN
SELECT 'Simple subscription system installed' as status,
       COUNT(*) as total_restaurants,
       COUNT(CASE WHEN subscription_status = 'active' THEN 1 END) as active_subscriptions,
       COUNT(CASE WHEN subscription_status = 'pending_payment' THEN 1 END) as pending_payments
FROM restaurants;