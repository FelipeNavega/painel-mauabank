#!/bin/bash
set -e

# Verifica e corrige permissões
echo "Verificando permissões..."
ls -la /var/www/html/public/
if [ -f /var/www/html/public/index.php ]; then
    echo "index.php existe, ajustando permissões"
    chmod 777 /var/www/html/public/index.php
    chown www-data:www-data /var/www/html/public/index.php
else
    echo "index.php não existe!"
    echo "Criando arquivo temporário para teste"
    echo "<?php phpinfo();" > /var/www/html/public/index.php
    chmod 777 /var/www/html/public/index.php
    chown www-data:www-data /var/www/html/public/index.php
fi

# Ajusta permissões recursivamente
chown -R www-data:www-data /var/www/html
chmod -R 777 /var/www/html

# Verifica configuração do PHP-FPM
php-fpm -t

# Inicia PHP-FPM em foreground
php-fpm -D

# Aguarda 2 segundos para garantir inicialização
sleep 2

# Verifica se o PHP-FPM está rodando
if ! pgrep "php-fpm" > /dev/null; then
    echo "ERRO: PHP-FPM não iniciou"
    exit 1
fi

# Inicia Nginx em foreground
nginx -g 'daemon off;'
