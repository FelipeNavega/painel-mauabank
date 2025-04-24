#!/bin/bash
set -e

# Verifica ambiente e sistema
echo "===== VERIFICAÇÃO DE AMBIENTE ====="
echo "Versão do PHP: $(php -v | head -n 1)"
echo "Versão do Nginx: $(nginx -v 2>&1)"
echo "Usuário atual: $(whoami)"
echo "Diretório atual: $(pwd)"

# Verificar espaço em disco
echo "===== ESPAÇO EM DISCO ====="
df -h

# Verifica estrutura de diretórios da aplicação
echo "===== ESTRUTURA DE DIRETÓRIOS ====="
ls -la /var/www/html/
echo ""
echo "===== VERIFICAÇÃO DE ARQUIVOS CHAVE ====="
echo "Verificando artisan:"
if [ -f /var/www/html/artisan ]; then
    echo "✅ artisan existe"
    chmod +x /var/www/html/artisan
else
    echo "❌ artisan não existe!"
fi

# Verifica variáveis de ambiente do Laravel
echo "===== VARIÁVEIS DE AMBIENTE DO LARAVEL ====="
echo "APP_NAME: ${APP_NAME:-Não definido}"
echo "APP_ENV: ${APP_ENV:-Não definido}"
echo "APP_DEBUG: ${APP_DEBUG:-Não definido}"
echo "APP_URL: ${APP_URL:-Não definido}"

# Criar arquivo .env a partir das variáveis de ambiente
echo "===== CRIANDO ARQUIVO .ENV ====="
cat > /var/www/html/.env << EOF
APP_NAME="${APP_NAME:-MauaBank}"
APP_ENV="${APP_ENV:-production}"
APP_KEY="${APP_KEY:-}"
APP_DEBUG="${APP_DEBUG:-true}"
APP_URL="${APP_URL:-https://mauabank.simulaimoveis.com.br}"

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

DB_CONNECTION="${DB_CONNECTION:-mysql}"
DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
DB_DATABASE="${DB_DATABASE:-laravel}"
DB_USERNAME="${DB_USERNAME:-root}"
DB_PASSWORD="${DB_PASSWORD:-}"

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120
EOF

chmod 666 /var/www/html/.env
echo "✅ .env criado com sucesso"

# Verifica pasta public e index.php
echo "===== VERIFICAÇÃO DE PUBLIC ====="
ls -la /var/www/html/public/

if [ -f /var/www/html/public/index.php ]; then
    echo "✅ index.php existe, ajustando permissões"
    chmod 777 /var/www/html/public/index.php
    chown www-data:www-data /var/www/html/public/index.php
    echo "Conteúdo do index.php:"
    head -n 10 /var/www/html/public/index.php
else
    echo "❌ index.php não existe!"
    echo "Criando arquivo temporário para teste"
    echo "<?php phpinfo();" > /var/www/html/public/index.php
    chmod 777 /var/www/html/public/index.php
    chown www-data:www-data /var/www/html/public/index.php
fi

# Cria diretórios de cache e storage com permissões corretas
echo "===== CONFIGURANDO DIRETÓRIOS DE CACHE E STORAGE ====="
mkdir -p /var/www/html/storage/framework/cache
mkdir -p /var/www/html/storage/framework/sessions
mkdir -p /var/www/html/storage/framework/views
mkdir -p /var/www/html/bootstrap/cache

chmod -R 777 /var/www/html/storage
chmod -R 777 /var/www/html/bootstrap/cache
chown -R www-data:www-data /var/www/html/storage
chown -R www-data:www-data /var/www/html/bootstrap/cache

# Gera chave da aplicação se necessário e limpa cache
if [ -f /var/www/html/artisan ]; then
    echo "===== COMANDOS LARAVEL ====="
    cd /var/www/html
    php artisan key:generate --force || echo "Não foi possível gerar a chave"
    php artisan config:clear || echo "Não foi possível limpar o cache de configuração"
    php artisan cache:clear || echo "Não foi possível limpar o cache"
    php artisan route:clear || echo "Não foi possível limpar o cache de rotas"
    php artisan view:clear || echo "Não foi possível limpar o cache de views"
    cd -
fi

# Ajusta permissões recursivamente
echo "===== AJUSTE DE PERMISSÕES ====="
chown -R www-data:www-data /var/www/html
chmod -R 777 /var/www/html
echo "Permissões ajustadas"

# Remover configuração padrão do Nginx que conflita
echo "===== AJUSTANDO CONFIGURAÇÃO DO NGINX ====="
if [ -f /etc/nginx/sites-enabled/default ]; then
    echo "Removendo arquivo de configuração default do Nginx"
    rm -f /etc/nginx/sites-enabled/default
fi

# Verificar configuração do nginx
echo "===== VERIFICAÇÃO DO NGINX ====="
nginx -t
cat /etc/nginx/conf.d/default.conf

# Verifica configuração do PHP-FPM
echo "===== VERIFICAÇÃO DO PHP-FPM ====="
php-fpm -t

# Inicia PHP-FPM em foreground
echo "===== INICIANDO PHP-FPM ====="
php-fpm -D

# Aguarda para garantir inicialização
sleep 2

# Verifica se o PHP-FPM está rodando
if ! pgrep "php-fpm" > /dev/null; then
    echo "❌ ERRO: PHP-FPM não iniciou"
    exit 1
else
    echo "✅ PHP-FPM iniciado com sucesso"
fi

# Inicia Nginx em foreground
echo "===== INICIANDO NGINX ====="
nginx -g 'daemon off;'
