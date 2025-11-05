-- ============================================
-- TABLAS DE SUSCRIPCIONES PARA MULTI-RESTAURANTE
-- ============================================

-- Tabla de suscripciones
CREATE TABLE IF NOT EXISTS restaurant_subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending_payment', -- pending_payment, active, suspended, cancelled
    monthly_fee DECIMAL(10,2) DEFAULT 50000.00,
    start_date DATE,
    end_date DATE,
    next_payment_date DATE NOT NULL,
    payment_method VARCHAR(50) DEFAULT 'bank_transfer',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(restaurant_id)
);

-- Tabla de pagos
CREATE TABLE IF NOT EXISTS restaurant_payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    subscription_id UUID NOT NULL REFERENCES restaurant_subscriptions(id) ON DELETE CASCADE,
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- pending, confirmed, rejected
    payment_method VARCHAR(50) DEFAULT 'bank_transfer',
    transaction_reference TEXT,
    confirmation_date DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Habilitar RLS
ALTER TABLE restaurant_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE restaurant_payments ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para suscripciones
CREATE POLICY "Restaurant owners can view their subscription" ON restaurant_subscriptions
    FOR SELECT USING (
        restaurant_id IN (
            SELECT id FROM restaurants WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Restaurant owners can update their subscription" ON restaurant_subscriptions
    FOR UPDATE USING (
        restaurant_id IN (
            SELECT id FROM restaurants WHERE auth_user_id = auth.uid()
        )
    );

-- Políticas RLS para pagos
CREATE POLICY "Restaurant owners can view their payments" ON restaurant_payments
    FOR SELECT USING (
        restaurant_id IN (
            SELECT id FROM restaurants WHERE auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Restaurant owners can create payment records" ON restaurant_payments
    FOR INSERT WITH CHECK (
        restaurant_id IN (
            SELECT id FROM restaurants WHERE auth_user_id = auth.uid()
        )
    );

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_restaurant_subscriptions_restaurant_id ON restaurant_subscriptions(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_restaurant_subscriptions_status ON restaurant_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_restaurant_subscriptions_next_payment ON restaurant_subscriptions(next_payment_date);
CREATE INDEX IF NOT EXISTS idx_restaurant_payments_subscription_id ON restaurant_payments(subscription_id);
CREATE INDEX IF NOT EXISTS idx_restaurant_payments_restaurant_id ON restaurant_payments(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_restaurant_payments_status ON restaurant_payments(status);

-- Trigger para actualizar updated_at
CREATE TRIGGER update_restaurant_subscriptions_updated_at BEFORE UPDATE ON restaurant_subscriptions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Función para verificar el estado de suscripción de un restaurante
CREATE OR REPLACE FUNCTION check_restaurant_subscription_status(restaurant_uuid UUID)
RETURNS TEXT AS $$
DECLARE
    sub_status TEXT;
    next_payment DATE;
BEGIN
    SELECT status, next_payment_date INTO sub_status, next_payment
    FROM restaurant_subscriptions 
    WHERE restaurant_id = restaurant_uuid;
    
    IF sub_status IS NULL THEN
        RETURN 'no_subscription';
    END IF;
    
    IF sub_status = 'active' AND next_payment < CURRENT_DATE THEN
        -- Actualizar a suspendido si el pago está vencido
        UPDATE restaurant_subscriptions 
        SET status = 'suspended' 
        WHERE restaurant_id = restaurant_uuid;
        RETURN 'suspended';
    END IF;
    
    RETURN sub_status;
END;
$$ LANGUAGE plpgsql;

-- Función para activar suscripción tras pago confirmado
CREATE OR REPLACE FUNCTION activate_restaurant_subscription(restaurant_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Activar el restaurante
    UPDATE restaurants 
    SET is_active = true 
    WHERE id = restaurant_uuid;
    
    -- Activar la suscripción
    UPDATE restaurant_subscriptions 
    SET 
        status = 'active',
        start_date = CURRENT_DATE,
        next_payment_date = CURRENT_DATE + INTERVAL '1 month'
    WHERE restaurant_id = restaurant_uuid;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Comentarios
COMMENT ON TABLE restaurant_subscriptions IS 'Suscripciones mensuales de restaurantes';
COMMENT ON TABLE restaurant_payments IS 'Registro de pagos de suscripciones';
COMMENT ON FUNCTION check_restaurant_subscription_status IS 'Verifica y actualiza el estado de suscripción';
COMMENT ON FUNCTION activate_restaurant_subscription IS 'Activa un restaurante tras confirmar pago';