#!/bin/bash

# Verifica si existe el directorio para los clientes de WireGuard
CLIENT_DIR="/home/wireguardvpn/clientes"
if [ ! -d "$CLIENT_DIR" ]; then
    echo "Creando el directorio para los clientes de WireGuard..."
    mkdir -p "$CLIENT_DIR"
    chmod 700 "$CLIENT_DIR"  # Permisos restringidos
fi

# Función para verificar si un nombre de cliente ya existe
check_client_exists() {
    local client_name="$1"
    if [ -d "$CLIENT_DIR/$client_name" ]; then
        return 0  # El cliente ya existe
    else
        return 1  # El cliente no existe
    fi
}

# Función para generar una nueva configuración de cliente WireGuard
create_client() {
    echo "¿Cómo se llama el cliente de WireGuard? (sin espacios ni caracteres especiales):"
    read client_name

    # Verifica si el cliente ya existe
    while check_client_exists "$client_name"; do
        echo "Error: El cliente '$client_name' ya existe. Elige otro nombre."
        read client_name
    done

    # Verificar si la IP está en uso
    ip_address="10.0.0.2/32"
    while [ -f "$CLIENT_DIR/$client_name/$ip_address.conf" ]; do
        echo "La dirección IP '$ip_address' ya está en uso. Asignando una nueva IP..."
        ip_address="10.0.0.$((RANDOM % 254 + 2))/32"  # Generar una nueva IP en el rango
    done

    # Crea la carpeta del cliente
    mkdir -p "$CLIENT_DIR/$client_name"
    chmod 700 "$CLIENT_DIR/$client_name"  # Permisos restringidos

    # Generar claves para el cliente
    wg genkey | tee "$CLIENT_DIR/$client_name/private.key" | wg pubkey > "$CLIENT_DIR/$client_name/public.key"

    # Crear la configuración para el cliente
    echo "[Interface]" > "$CLIENT_DIR/$client_name/$client_name.conf"
    echo "PrivateKey = $(cat $CLIENT_DIR/$client_name/private.key)" >> "$CLIENT_DIR/$client_name/$client_name.conf"
    echo "Address = $ip_address" >> "$CLIENT_DIR/$client_name/$client_name.conf"
    echo "" >> "$CLIENT_DIR/$client_name/$client_name.conf"
    echo "[Peer]" >> "$CLIENT_DIR/$client_name/$client_name.conf"
    echo "PublicKey = <Server Public Key>" >> "$CLIENT_DIR/$client_name/$client_name.conf"
    echo "Endpoint = <Server IP>:51820" >> "$CLIENT_DIR/$client_name/$client_name.conf"
    echo "AllowedIPs = 0.0.0.0/0" >> "$CLIENT_DIR/$client_name/$client_name.conf"
    echo "PersistentKeepalive = 25" >> "$CLIENT_DIR/$client_name/$client_name.conf"

    # Crear un código QR del archivo de configuración
    qrencode -t png < "$CLIENT_DIR/$client_name/$client_name.conf" -o "$CLIENT_DIR/$client_name/$client_name-qr.png"

    # Crear un archivo resumen con los parámetros de configuración
    cat > "$CLIENT_DIR/$client_name/summary.txt" << EOF
Cliente WireGuard: $client_name
-----------------------------
PrivateKey = $(cat $CLIENT_DIR/$client_name/private.key)
Address = $ip_address
PublicKey = <Server Public Key>
Endpoint = <Server IP>:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25

# Descripción de parámetros:
# PrivateKey: La clave privada del cliente.
# Address: Dirección IP estática asignada al cliente.
# PublicKey: La clave pública del servidor WireGuard.
# Endpoint: Dirección IP pública y puerto del servidor WireGuard.
# AllowedIPs: Rango de direcciones IP permitidas.
# PersistentKeepalive: Tiempo en segundos para enviar un paquete para mantener la conexión activa.
EOF

    echo "Cliente '$client_name' creado exitosamente. Código QR generado y configuración guardada en su carpeta."
}

# Función para modificar un cliente WireGuard
modify_client() {
    echo "Selecciona el cliente que deseas modificar:"
    select client in $(ls $CLIENT_DIR); do
        if [ -n "$client" ]; then
            echo "Has seleccionado el cliente: $client"
            echo "¿Qué deseas hacer?"
            echo "1. Ver la configuración"
            echo "2. Modificar la configuración con nano"
            echo "3. Borrar y rehacer la configuración desde cero"
            echo "4. Borrar el cliente"
            read -p "Opción (1-4): " option
            case $option in
                1) 
                    cat "$CLIENT_DIR/$client/summary.txt"
                    ;;
                2)
                    nano "$CLIENT_DIR/$client/$client.conf"
                    ;;
                3)
                    echo "Rehaciendo la configuración para el cliente '$client'..."
                    rm -rf "$CLIENT_DIR/$client"
                    create_client
                    ;;
                4)
                    echo "Borrando el cliente '$client'..."
                    rm -rf "$CLIENT_DIR/$client"
                    ;;
                *)
                    echo "Opción inválida."
                    ;;
            esac
            break
        else
            echo "Opción inválida. Intenta de nuevo."
        fi
    done
}

# Función para borrar todos los clientes
delete_all_clients() {
    echo "¿Estás seguro de que deseas borrar todos los clientes? (si/no)"
    read confirmation
    if [[ "$confirmation" == "si" ]]; then
        rm -rf "$CLIENT_DIR/*"
        echo "Todos los clientes de WireGuard han sido borrados."
    else
        echo "Operación cancelada."
    fi
}

# Función para mostrar el menú y gestionar las opciones
show_menu() {
    echo "Gestión de clientes WireGuard"
    echo "1. Crear un cliente WireGuard"
    echo "2. Modificar un cliente WireGuard"
    echo "3. Borrar un cliente WireGuard"
    echo "4. Borrar todos los clientes WireGuard"
    echo "5. Salir"
    read -p "Elige una opción (1-5): " option

    case $option in
        1) create_client ;;
        2) modify_client ;;
        3)
            echo "Selecciona el cliente que deseas borrar:"
            select client in $(ls $CLIENT_DIR); do
                if [ -n "$client" ]; then
                    rm -rf "$CLIENT_DIR/$client"
                    echo "Cliente '$client' borrado."
                    break
                else
                    echo "Opción inválida. Intenta de nuevo."
                fi
            done
            ;;
        4) delete_all_clients ;;
        5) exit 0 ;;
        *)
            echo "Opción inválida."
            ;;
    esac
}

# Mostrar el menú inicial
while true; do
    show_menu
done
