# ARM1 Rentzone Application - Kubernetes Optimized Dockerfile
# Single-purpose container for web application only (database is separate RDS)
FROM php:8.1-apache

# Install system dependencies and PHP extensions required for Laravel
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    default-mysql-client \
    gettext-base \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Composer for PHP dependency management
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy and extract Rentzone application
COPY rentzone.zip /tmp/rentzone.zip
RUN cd /tmp && unzip rentzone.zip && cp -r rentzone/* /var/www/html/ && rm -rf /tmp/rentzone*

# Set proper ownership and permissions for Laravel
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Enable Apache mod_rewrite for Laravel routing
RUN a2enmod rewrite

# Configure Apache virtual host for Laravel
COPY apache-config.conf /etc/apache2/sites-available/000-default.conf

# Create Laravel storage and cache directories with proper permissions
RUN mkdir -p storage/logs storage/framework/cache storage/framework/sessions storage/framework/views bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Copy environment configuration template
COPY .env.template /var/www/html/.env

# Create health check file
RUN echo '<?php echo "OK"; ?>' > /var/www/html/health.php

# Copy startup script that will configure environment variables
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose port 80 only (no MySQL - that's in RDS)
EXPOSE 80

# Health check for Kubernetes
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Use custom entrypoint to configure environment variables at runtime
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]