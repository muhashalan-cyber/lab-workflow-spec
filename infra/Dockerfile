# Partly verified: a build session brought this stack up on 10 Nov 2026 and corrected
# the PHP pin and the entrypoint. Still verify the tag and extension list against the
# Laravel and Filament versions you install.
#
# PHP 8.4, not 8.3: current Laravel 12 pulls Symfony 8 components requiring PHP >= 8.4.1,
# so Filament 4 will not install on 8.3 at all.

FROM dunglas/frankenphp:php8.4-alpine AS base

RUN install-php-extensions \
      pdo_pgsql pgsql redis intl zip gd bcmath opcache pcntl exif

# curl IS present in the current FrankenPHP Alpine image — an earlier revision of this
# file claimed otherwise and was wrong. Installing it explicitly keeps the compose
# healthcheck working if that ever stops being true; harmless either way.
RUN apk add --no-cache curl

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

# Octane is NOT a default Laravel dependency - `composer require laravel/octane` and
# `php artisan octane:install --server=frankenphp` first. Verify the command against the
# Octane version you install; the documented form is:
ENTRYPOINT ["php", "artisan", "octane:start", "--server=frankenphp", "--host=0.0.0.0", "--port=8080"]

# Without Octane, serve through FrankenPHP's own Caddy config instead and drop this
# ENTRYPOINT. Either is fine; decide once and record which.
