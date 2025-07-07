#!/bin/bash
set -e

# Configure environment variables from Kubernetes secrets/configmaps
export DB_HOST=${DB_HOST:-"arm1-rds-instance.cluster-xyz.eu-west-1.rds.amazonaws.com"}
export DB_DATABASE=${DB_DATABASE:-"ARM1"}
export DB_USERNAME=${DB_USERNAME:-"ARM1"}
export DB_PASSWORD=${DB_PASSWORD:-""}
export APP_URL=${APP_URL:-"http://localhost"}

# Replace environment variables in .env file
envsubst < /var/www/html/.env > /var/www/html/.env.tmp && mv /var/www/html/.env.tmp /var/www/html/.env

# Generate Laravel application key if not set
if [ -z "$APP_KEY" ]; then
    php artisan key:generate --force
fi

# Run Laravel optimizations
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Run database migrations (optional - uncomment if needed)
# php artisan migrate --force

# Start Apache
exec "$@"