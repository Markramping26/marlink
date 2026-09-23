FROM php:8.2-cli-alpine

# Install PDO MySQL extension
RUN docker-php-ext-install pdo pdo_mysql

WORKDIR /var/www/html

# Copy API files
COPY . /var/www/html/

# Ensure uploads directory is writable
RUN mkdir -p /var/www/html/uploads/avatars /var/www/html/uploads/chat \
    && chmod -R 777 /var/www/html/uploads

EXPOSE 10000

ENV PORT=10000

CMD ["sh", "-c", "php -S 0.0.0.0:${PORT:-10000} server.php"]
