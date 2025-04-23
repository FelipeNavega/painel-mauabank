#!/bin/bash

# Script para limpar arquivos temporários e de cache
echo "Iniciando limpeza do projeto..."

# Limpar storage/logs
echo "Limpando logs..."
rm -f storage/logs/*.log

# Limpar caches
echo "Limpando caches..."
rm -rf storage/framework/cache/*
rm -rf storage/framework/sessions/*
rm -rf storage/framework/views/*

# Limpar arquivos temporários
echo "Limpando arquivos temporários..."
find . -name "*.swp" -type f -delete
find . -name "*.swo" -type f -delete
find . -name "*~" -type f -delete

# Remover arquivos grandes desnecessários
echo "Removendo arquivos grandes..."
find . -name "*.zip" -type f -delete
find . -name "*.rar" -type f -delete
find . -name "*.tar.gz" -type f -delete

echo "Limpeza concluída!"
