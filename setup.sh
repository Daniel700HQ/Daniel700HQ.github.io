#!/bin/bash

# Función para agregar los repositorios si el usuario lo desea
add_repositories() {
    echo "Añadiendo los repositorios de Debian, Debian Security y Debian Updates..."
    echo "deb http://deb.debian.org/debian/ bookworm main contrib non-free" > /etc/apt/sources.list
    echo "deb http://security.debian.org/debian-security bookworm-security main contrib non-free" >> /etc/apt/sources.list
    echo "deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free" >> /etc/apt/sources.list
    apt update
}

# Función para instalar xfce, xfce goodies y firefox-esr
install_xfce_firefox() {
    echo "Instalando XFCE, XFCE goodies y Firefox ESR..."
    apt install -y xfce4 xfce4-goodies firefox-esr
}

# Función para instalar WireGuard
install_wireguard() {
    echo "Instalando WireGuard..."
    apt install -y wireguard
}

# Variables locales para almacenar las respuestas
operation_repositories=""
operation_xfce_firefox=""
operation_wireguard=""

# Preguntar si desea agregar los repositorios
read -p "¿Deseas agregar los repositorios de Debian, Debian Security y Debian Updates? (si/no): " answer_repositories
if [[ "$answer_repositories" == "si" ]]; then
    operation_repositories="repositorios añadidos"
fi

# Preguntar si desea instalar XFCE, XFCE goodies y Firefox ESR
read -p "¿Deseas instalar XFCE, XFCE goodies y Firefox ESR? (si/no): " answer_xfce_firefox
if [[ "$answer_xfce_firefox" == "si" ]]; then
    operation_xfce_firefox="XFCE, XFCE goodies y Firefox ESR instalados"
fi

# Preguntar si desea instalar WireGuard
read -p "¿Deseas instalar WireGuard? (si/no): " answer_wireguard
if [[ "$answer_wireguard" == "si" ]]; then
    operation_wireguard="WireGuard instalado"
fi

# Mostrar al usuario las respuestas
echo "Resumen de las operaciones seleccionadas:"
echo "1. Repositorios: $operation_repositories"
echo "2. Instalación de XFCE, XFCE goodies y Firefox ESR: $operation_xfce_firefox"
echo "3. Instalación de WireGuard: $operation_wireguard"

# Confirmar con el usuario antes de ejecutar las operaciones
read -p "¿Confirmas estos cambios? (si/no): " confirm
if [[ "$confirm" == "si" ]]; then
    # Ejecutar las operaciones seleccionadas
    if [[ "$operation_repositories" == "repositorios añadidos" ]]; then
        add_repositories
    fi

    if [[ "$operation_xfce_firefox" == "XFCE, XFCE goodies y Firefox ESR instalados" ]]; then
        install_xfce_firefox
    fi

    if [[ "$operation_wireguard" == "WireGuard instalado" ]]; then
        install_wireguard
    fi

    echo "Operaciones completadas."
else
    echo "Operaciones canceladas."
fi
