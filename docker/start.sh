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
