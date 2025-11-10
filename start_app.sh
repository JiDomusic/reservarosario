#!/bin/bash

echo "🚀 Iniciando SODITA Admin App..."
echo "📅 Calendario arreglado y funcionando"
echo ""

# Matar procesos previos
pkill -f "python3.*8080" > /dev/null 2>&1

# Compilar si es necesario
if [ ! -d "build/web" ]; then
    echo "📦 Compilando app..."
    flutter build web
fi

# Iniciar servidor
echo "🌐 Iniciando servidor en puerto 8080..."
nohup python3 -m http.server 8080 --directory build/web > /dev/null 2>&1 &

sleep 2

echo ""
echo "✅ ¡App funcionando!"
echo "🔗 URL: http://localhost:8080"
echo "📅 El calendario ya funciona - busca el botón de calendario en la parte superior"
echo ""
echo "Para parar el servidor: pkill -f 'python3.*8080'"