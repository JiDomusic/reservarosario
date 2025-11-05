-- ============================================
-- ARREGLAR TABLAS DE SUSCRIPCIONES
-- ============================================

-- 1. ELIMINAR TABLAS EXISTENTES SI HAY ERRORES
DROP TABLE IF EXISTS restaurant_payments CASCADE;
DROP TABLE IF EXISTS restaurant_subscriptions CASCADE;

-- 2. CREAR TABLA DE SUSCRIPCIONES CORRECTAMENTE
CREATE TABLE restaurant_subscriptions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending_payment',
    monthly_fee DECIMAL(10,2) DEFAULT 50000.00,
    start_date DATE,
    end_date DATE,
    next_payment_date DATE NOT NULL DEFAULT (CURRENT_DATE + INTERVAL '30 days'),
    payment_method VARCHAR(50) DEFAULT 'bank_transfer',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(restaurant_id)
);

-- 3. CREAR TABLA DE PAGOS
CREATE TABLE restaurant_payments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    subscription_id UUID NOT NULL REFERENCES restaurant_subscriptions(id) ON DELETE CASCADE,
    restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'pending',
    payment_method VARCHAR(50) DEFAULT 'bank_transfer',
    transaction_reference TEXT,
    confirmation_date DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. HABILITAR RLS
ALTER TABLE restaurant_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE restaurant_payments ENABLE ROW LEVEL SECURITY;

-- 5. POLÍTICAS RLS PARA SUSCRIPCIONES
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

-- 6. POLÍTICAS RLS PARA PAGOS
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

-- 7. CREAR FUNCIÓN PARA ACTIVAR SUSCRIPCIÓN
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
    
    -- Si no existe suscripción, crearla
    INSERT INTO restaurant_subscriptions (restaurant_id, status, start_date, next_payment_date)
    SELECT restaurant_uuid, 'active', CURRENT_DATE, CURRENT_DATE + INTERVAL '1 month'
    WHERE NOT EXISTS (
        SELECT 1 FROM restaurant_subscriptions WHERE restaurant_id = restaurant_uuid
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 8. FUNCIÓN PARA VER ESTADO DE SUSCRIPCIONES
CREATE OR REPLACE FUNCTION get_subscription_status()
RETURNS TABLE(
    restaurant_name TEXT,
    email TEXT,
    status TEXT,
    next_payment_date DATE,
    days_until_payment INTEGER,
    is_active BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.name::TEXT,
        r.email::TEXT,
        COALESCE(s.status, 'no_subscription')::TEXT,
        s.next_payment_date,
        EXTRACT(days FROM (s.next_payment_date - CURRENT_DATE))::INTEGER,
        r.is_active
    FROM restaurants r
    LEFT JOIN restaurant_subscriptions s ON r.id = s.restaurant_id
    ORDER BY s.next_payment_date ASC NULLS LAST;
END;
$$ LANGUAGE plpgsql;

-- 9. INSERTAR SUSCRIPCIONES PARA RESTAURANTES EXISTENTES
INSERT INTO restaurant_subscriptions (restaurant_id, status, next_payment_date)
SELECT 
    id, 
    CASE WHEN is_active THEN 'active' ELSE 'pending_payment' END,
    CURRENT_DATE + INTERVAL '30 days'
FROM restaurants 
WHERE NOT EXISTS (
    SELECT 1 FROM restaurant_subscriptions WHERE restaurant_id = restaurants.id
);

-- 10. VERIFICAR INSTALACIÓN
SELECT 'Subscription system installed successfully' as status,
       COUNT(*) as total_subscriptions
FROM restaurant_subscriptions;