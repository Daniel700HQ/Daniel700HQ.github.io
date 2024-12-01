#!/bin/bash

# Script para diagnosticar y resolver problemas con el servicio WireGuard

WG_SERVICE="wg-quick@wg0"

# Función para comprobar el estado del servicio
check_service_status() {
    echo "Verificando el estado del servicio $WG_SERVICE..."
    systemctl status $WG_SERVICE --no-pager
    if systemctl is-active --quiet $WG_SERVICE; then
        echo "El servicio $WG_SERVICE está activo."
        return 0
    else
        echo "El servicio $WG_SERVICE no está activo."
        return 1
    fi
}

# Función para comprobar el archivo de configuración de WireGuard
check_config_file() {
    CONFIG_FILE="/etc/wireguard/wg0.conf"
    echo "Verificando el archivo de configuración: $CONFIG_FILE..."
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: El archivo de configuración $CONFIG_FILE no existe."
        return 1
    fi

    if ! wg showconf wg0 >/dev/null 2>&1; then
        echo "Error: El archivo de configuración contiene errores de sintaxis."
        return 1
    fi

    echo "El archivo de configuración parece estar correcto."
    return 0
}

# Función para comprobar si las claves privadas y públicas son válidas
check_keys() {
    echo "Verificando las claves de WireGuard..."
    PRIVATE_KEY=$(grep -Po '(?<=PrivateKey = )\S+' /etc/wireguard/wg0.conf)
    if [ -z "$PRIVATE_KEY" ]; then
        echo "Error: No se encontró una clave privada en la configuración."
        return 1
    fi

    if ! echo "$PRIVATE_KEY" | wg pubkey >/dev/null 2>&1; then
        echo "Error: La clave privada no es válida."
        return 1
    fi

    echo "Las claves parecen estar en orden."
    return 0
}

# Función para verificar que el módulo de WireGuard esté cargado
check_module() {
    echo "Verificando si el módulo de WireGuard está cargado..."
    if ! lsmod | grep -q wireguard; then
        echo "El módulo de WireGuard no está cargado. Intentando cargarlo..."
        modprobe wireguard
        if [ $? -ne 0 ]; then
            echo "Error: No se pudo cargar el módulo WireGuard."
            return 1
        fi
        echo "Módulo WireGuard cargado con éxito."
    else
        echo "El módulo de WireGuard ya está cargado."
    fi
    return 0
}

# Función para verificar el reenvío de IP
check_ip_forwarding() {
    echo "Verificando el reenvío de IP..."
    if [ "$(cat /proc/sys/net/ipv4/ip_forward)" -ne 1 ]; then
        echo "El reenvío de IP está deshabilitado. Habilitándolo..."
        echo 1 > /proc/sys/net/ipv4/ip_forward
        echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
        sysctl -p
    else
        echo "El reenvío de IP está habilitado."
    fi
}

# Función para reiniciar el servicio
restart_service() {
    echo "Intentando reiniciar el servicio $WG_SERVICE..."
    systemctl restart $WG_SERVICE
    if systemctl is-active --quiet $WG_SERVICE; then
        echo "El servicio $WG_SERVICE se reinició correctamente."
        return 0
    else
        echo "Error: El servicio $WG_SERVICE no pudo reiniciarse."
        return 1
    fi
}

# Función para mostrar opciones de resolución manual
manual_help() {
    echo "Si el problema persiste, considera las siguientes acciones:"
    echo "1. Verifica los logs con: journalctl -u $WG_SERVICE"
    echo "2. Revisa posibles conflictos de puertos con: netstat -tunlp"
    echo "3. Asegúrate de que las interfaces y redes configuradas sean correctas."
    echo "4. Consulta la documentación oficial de WireGuard."
}

# Ejecución del script
echo "Iniciando diagnóstico de problemas con WireGuard..."

check_service_status || {
    check_config_file || exit 1
    check_keys || exit 1
    check_module || exit 1
    check_ip_forwarding
    restart_service || manual_help
}

echo "Diagnóstico completado."
