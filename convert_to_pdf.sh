#!/bin/bash

# Script para convertir HTML a PDF manteniendo estilos
# Uso: ./convert_to_pdf.sh

echo "🔄 Convirtiendo HTML a PDF..."

# Verificar si wkhtmltopdf está instalado
if ! command -v wkhtmltopdf &> /dev/null; then
    echo "📦 Instalando wkhtmltopdf..."
    sudo apt update && sudo apt install -y wkhtmltopdf
fi

# Convertir a PDF
wkhtmltopdf \
  --page-size A4 \
  --orientation Portrait \
  --margin-top 8mm \
  --margin-bottom 8mm \
  --margin-left 8mm \
  --margin-right 8mm \
  --enable-local-file-access \
  --print-media-type \
  --no-outline \
  --disable-smart-shrinking \
  --zoom 0.95 \
  PROPUESTA_COMERCIAL_SODITA.html \
  SODITA_Propuesta_Comercial_$(date +%Y%m%d).pdf

if [ $? -eq 0 ]; then
    echo "✅ PDF creado exitosamente: SODITA_Propuesta_Comercial_$(date +%Y%m%d).pdf"
    echo "📂 Ubicación: $(pwd)/SODITA_Propuesta_Comercial_$(date +%Y%m%d).pdf"
else
    echo "❌ Error al crear el PDF"
fi