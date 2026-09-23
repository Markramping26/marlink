FROM php:8.2-cli-alpine

# Install PDO MySQL and SQLite extensions
RUN apk add --no-cache sqlite-dev \
    && docker-php-ext-install pdo pdo_mysql pdo_sqlite

WORKDIR /var/www/html

# Copy API files from marlink_api
COPY marlink_api/ /var/www/html/

# Ensure uploads and database directories are writable
RUN mkdir -p /var/www/html/uploads/avatars /var/www/html/uploads/chat /var/www/html/database \
    && chmod -R 777 /var/www/html/uploads /var/www/html/database

EXPOSE 10000

ENV PORT=10000

CMD ["sh", "-c", "php -S 0.0.0.0:${PORT:-10000} server.php"]
