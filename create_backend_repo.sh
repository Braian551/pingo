#!/bin/bash
echo "🚀 Creando repositorio separado para el backend..."

# Crear nuevo repo en GitHub primero desde el navegador
echo ""
echo "📋 PASO 1: Ve a https://github.com/new"
echo "   - Repository name: pinggo-backend"
echo "   - Description: Backend API for PingGo app"
echo "   - Public/Private: según prefieras"
echo "   - NO marques 'Add a README file'"
echo ""
read -p "Presiona Enter cuando hayas creado el repo..."

# Inicializar git en la carpeta backend-deploy
cd backend-deploy
git init
git add .
git commit -m "Initial backend deployment for PingGo"

# Configurar remote
echo ""
echo "📋 PASO 2: Configurando remote..."
read -p "Tu username de GitHub: " username
git remote add origin "https://github.com/${username}/pinggo-backend.git"

# Push
echo ""
echo "📋 PASO 3: Subiendo a GitHub..."
git push -u origin main

echo ""
echo "✅ ¡Repositorio backend creado exitosamente!"
echo "Ahora puedes deployarlo en Railway conectando el repo 'pinggo-backend'"