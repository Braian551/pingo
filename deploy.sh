#!/bin/bash
# Railway deployment script

echo "🚀 Starting Railway deployment..."

# Change to backend directory
cd pingo/backend

# Install dependencies
composer install --no-dev --optimize-autoloader

# Create necessary directories
mkdir -p logs uploads

# Set permissions
chmod 755 logs uploads

# Run database migrations if database is available
if [ -n "$MYSQLHOST" ]; then
    echo "📊 Running database migrations..."
    php migrations/run_migrations.php
    echo "✅ Database migrations completed!"
else
    echo "⚠ Database not configured yet. Run migrations manually after setup."
fi

echo "✅ Deployment setup complete!"
echo "🌐 Your app will be available at: $RAILWAY_STATIC_URL"