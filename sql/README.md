# Gestión de Base de Datos SQL

## Archivos principales

### `sodita_completo.sql` ✅ **USAR ESTE**
- **Script completo para SODITA funcionando**
- Contiene las 11 mesas con capacidades variadas (4-50 personas)
- Políticas RLS configuradas correctamente
- Triggers y funciones completas
- **Ejecutar en:** https://supabase.com/dashboard/project/weurjculqnxvtmbqltjo

## Plantillas

### `templates/restaurant_template.sql`
- Plantilla base para crear nuevos restaurantes
- Reemplazar `{RESTAURANT_NAME}`, `{TABLE_COUNT}`, `{PREFIX}` según sea necesario
- Usar como base para otros restaurantes como Palacio Tangó

## Instrucciones

1. **Para SODITA:** Ejecutar `sodita_completo.sql` en Supabase
2. **Para nuevos restaurantes:** Copiar `restaurant_template.sql`, personalizar y ejecutar
3. **Mantener:** Solo estos archivos, el resto fueron eliminados por obsoletos

## Estado actual
- ✅ SODITA: Base de datos configurada y lista
- ⏳ Otros restaurantes: Usar plantilla cuando sea necesario