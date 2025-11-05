-- ============================================
-- ARREGLAR POLÍTICAS RLS PARA PERMITIR REGISTRO
-- ============================================

-- Eliminar política problemática
DROP POLICY IF EXISTS "Restaurant owners can manage their own data" ON restaurants;

-- Crear políticas separadas más específicas
-- Política para permitir INSERT (cualquier usuario autenticado puede crear)
CREATE POLICY "Authenticated users can create restaurants" ON restaurants
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Política para SELECT propio
CREATE POLICY "Restaurant owners can view their own data" ON restaurants
    FOR SELECT USING (auth_user_id = auth.uid());

-- Política para UPDATE propio
CREATE POLICY "Restaurant owners can update their own data" ON restaurants
    FOR UPDATE USING (auth_user_id = auth.uid());

-- Política para DELETE propio
CREATE POLICY "Restaurant owners can delete their own data" ON restaurants
    FOR DELETE USING (auth_user_id = auth.uid());

-- La política pública para SELECT ya existe y está bien
-- CREATE POLICY "Public can view active restaurants" ON restaurants
--     FOR SELECT USING (is_active = true);

-- Comentario
COMMENT ON POLICY "Authenticated users can create restaurants" ON restaurants IS 'Permite a usuarios autenticados crear restaurantes';