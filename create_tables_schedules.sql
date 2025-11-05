-- CREAR MESAS Y HORARIOS PARA RESTAURANTES
-- Ejecutar esto DESPUÉS del script anterior

-- Crear función para generar mesas
CREATE OR REPLACE FUNCTION create_restaurant_tables()
RETURNS void AS $$
DECLARE
    restaurant_record RECORD;
    i INTEGER;
    table_capacity INTEGER;
    table_location TEXT;
BEGIN
    -- Para cada restaurante
    FOR restaurant_record IN SELECT id, total_tables FROM restaurants LOOP
        -- Crear mesas
        FOR i IN 1..restaurant_record.total_tables LOOP
            -- Determinar capacidad
            IF i <= (restaurant_record.total_tables * 0.4) THEN
                table_capacity := 2;  -- 40% mesas para 2
            ELSIF i <= (restaurant_record.total_tables * 0.7) THEN
                table_capacity := 4;  -- 30% mesas para 4
            ELSE
                table_capacity := 6;  -- 30% mesas para 6
            END IF;
            
            -- Determinar ubicación
            IF i <= (restaurant_record.total_tables * 0.5) THEN
                table_location := 'Interior';
            ELSE
                table_location := 'Terraza';
            END IF;
            
            -- Insertar mesa
            INSERT INTO restaurant_tables (restaurant_id, table_number, capacity, location)
            VALUES (restaurant_record.id, i, table_capacity, table_location);
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Crear función para generar horarios
CREATE OR REPLACE FUNCTION create_restaurant_schedules()
RETURNS void AS $$
DECLARE
    restaurant_record RECORD;
    i INTEGER;
    open_hour TEXT;
    close_hour TEXT;
BEGIN
    -- Para cada restaurante
    FOR restaurant_record IN SELECT id FROM restaurants LOOP
        -- Crear horarios para cada día (0=Domingo, 6=Sábado)
        FOR i IN 0..6 LOOP
            -- Determinar horarios
            IF i = 0 THEN
                open_hour := '10:00:00';  -- Domingo abre más tarde
            ELSE
                open_hour := '08:00:00';
            END IF;
            
            IF i IN (0,6) THEN
                close_hour := '00:00:00';  -- Fines de semana cierran más tarde
            ELSE
                close_hour := '23:00:00';
            END IF;
            
            -- Insertar horario
            INSERT INTO restaurant_schedules (restaurant_id, day_of_week, open_time, close_time, is_closed)
            VALUES (restaurant_record.id, i, open_hour::TIME, close_hour::TIME, false);
        END LOOP;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Ejecutar las funciones
SELECT create_restaurant_tables();
SELECT create_restaurant_schedules();

-- Limpiar funciones temporales
DROP FUNCTION create_restaurant_tables();
DROP FUNCTION create_restaurant_schedules();