-- ================================================
-- AGREGAR NUEVO RESTAURANTE (PLANTILLA)
-- ================================================
-- Copiar este script y reemplazar los valores según el restaurante

-- EJEMPLO: PALACIO TANGÓ
INSERT INTO restaurantes (
    nombre, 
    slug, 
    descripcion, 
    direccion, 
    telefono,
    email,
    admin_email, 
    logo_url, 
    imagen_principal,
    color_primario, 
    color_secundario, 
    alias_banco,
    cbu_banco,
    suscripcion_activa
) VALUES (
    'Palacio Tangó', 
    'palacio-tango', 
    'Elegante restaurante de tango y gastronomía argentina. Noches mágicas con espectáculos en vivo.',
    'Av. Pellegrini 1250, Rosario 2000',
    '+54 341 987-6543',
    'info@palaciotango.com.ar',
    'admin@palaciotango.com.ar',
    'https://example.com/palacio-logo.png',
    'https://example.com/palacio-main.jpg',
    '#8B0000', -- Rojo elegante
    '#DC143C', -- Rojo más claro
    'PALACIO.TANGO.RESERVAS',
    '1234567890123456789012',
    FALSE -- Empieza sin suscripción
);

-- INSERTAR MESAS DEL PALACIO TANGÓ (10 mesas ejemplo)
INSERT INTO mesas_restaurante (restaurante_id, numero, capacidad, ubicacion, descripcion)
SELECT 
    (SELECT id FROM restaurantes WHERE slug = 'palacio-tango'),
    numero,
    capacidad,
    ubicacion,
    descripcion
FROM (VALUES
    (1, 4, 'Palco VIP', 'Mesa exclusiva con vista al escenario'),
    (2, 6, 'Sector Central', 'Vista panorámica del salón principal'),
    (3, 2, 'Mesa Romántica', 'Perfecta para parejas, ambiente íntimo'),
    (4, 8, 'Mesa Familiar', 'Ideal para grupos grandes'),
    (5, 4, 'Cerca del escenario', 'Primera fila para el espectáculo'),
    (6, 6, 'Palco Lateral', 'Vista lateral privilegiada'),
    (7, 4, 'Sector Medio', 'Ubicación central y cómoda'),
    (8, 2, 'Mesa de Corner', 'Privacidad y tranquilidad'),
    (9, 10, 'Mesa de Celebración', 'Para eventos especiales'),
    (10, 4, 'Vista Lateral', 'Perspectiva única del show')
) AS mesas(numero, capacidad, ubicacion, descripcion);

-- ================================================
-- VERIFICAR QUE SE CREÓ CORRECTAMENTE
-- ================================================
SELECT 
    r.nombre,
    r.slug,
    r.direccion,
    COUNT(m.id) as total_mesas
FROM restaurantes r
LEFT JOIN mesas_restaurante m ON r.id = m.restaurante_id
WHERE r.slug = 'palacio-tango'
GROUP BY r.id, r.nombre, r.slug, r.direccion;