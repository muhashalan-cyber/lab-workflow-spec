# NOT TESTED — no base image was pulled in the sandbox that wrote this.
# Verify the FrankenPHP tag and the extension list against the Laravel and Filament
# versions you actually install.

FROM dunglas/frankenphp:php8.3-alpine AS base

RUN install-php-extensions \
      pdo_pgsql pgsql redis intl zip gd bcmath opcache pcntl exif

WORKDIR /app

# Composer from its official image, pinned by you
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Dependencies first so the layer caches
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-interaction

COPY . .
RUN composer dump-autoload --optimize --no-dev \
 && php artisan storage:link || true

# Front-end assets. Drop this stage if you build assets outside the image.
# RUN npm ci && npm run build

ENV SERVER_NAME=:8080
EXPOSE 8080

# Run as a non-root user. FrankenPHP needs capabilities to bind <1024; it binds 8080
# here and Caddy handles 443, so no capability is required.
RUN addgroup -g 1000 app && adduser -u 1000 -G app -s /bin/sh -D app \
 && chown -R app:app /app
USER app

ENTRYPOINT ["php", "artisan", "octane:frankenphp", "--host=0.0.0.0", "--port=8080"]
