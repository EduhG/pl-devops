FROM composer:2.9.5 AS builder

WORKDIR /app

COPY composer.json composer.lock* ./
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress

COPY . /app

# Optimize autoloader
RUN composer dump-autoload --optimize --classmap-authoritative

FROM php:8.3-fpm-alpine

# Non-root user
RUN addgroup -g 1000 app && adduser -G app -g app -s /bin/sh -D app

WORKDIR /var/www

# Copy built app
COPY --from=builder /app /var/www

# Set ownership
RUN chown -R app:app /var/www

USER app

EXPOSE 9000

CMD ["php-fpm", "-F"]
