#!/bin/bash

# Colores
CYAN='\033[1;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# Verificar si el script se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[!] Este script debe ejecutarse como root. Usa: sudo $0${RESET}"
   exit 1
fi

# Verificar si Nmap está instalado
if ! command -v nmap &> /dev/null; then
    echo -e "${RED}[!] Nmap no está instalado. Instálalo con: sudo apt install nmap${RESET}"
    exit 1
fi

# Banner
clear
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════╗"
echo "║              NMAP-RECON ULTRA               ║"
echo "║       Escaneos de Red para Pentesters       ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${RESET}"

# Función para elegir si guardar
guardar_resultado() {
    read -p "¿Quieres guardar el resultado? (s/n): " save
    if [[ "$save" == "s" ]]; then
        read -p ">> Ruta del archivo (ej: /home/usuario/scan.txt): " file
        OUTPUT="-oN $file"
        OUTPUT_RUTA="$file"
    else
        OUTPUT=""
        OUTPUT_RUTA=""
    fi
}

# Función para buscar vulnerabilidades
buscar_vulnerabilidades() {
    echo -e "${CYAN}[*] Buscando vulnerabilidades y puertos abiertos...${RESET}"
    guardar_resultado
    TEMPFILE=$(mktemp)

    nmap -p- --script vuln,vulners "$objetivo" -oN "$TEMPFILE"

    echo -e "${YELLOW}\n[+] Puertos abiertos:${RESET}"
    grep -E "^[0-9]+/tcp\s+open" "$TEMPFILE" || echo -e "${RED}:( No se encontraron puertos abiertos${RESET}"

    echo -e "${YELLOW}\n[+] Vulnerabilidades encontradas:${RESET}"
    if grep -i "CVE-" "$TEMPFILE" > /dev/null; then
        grep -i "CVE-" "$TEMPFILE" | sort | uniq
    else
        echo -e "${RED}:( No se encontraron vulnerabilidades conocidas${RESET}"
    fi

    if [[ "$OUTPUT_RUTA" != "" ]]; then
        cp "$TEMPFILE" "$OUTPUT_RUTA"
        echo -e "${GREEN}[+] Resultado guardado en $OUTPUT_RUTA${RESET}"
    fi

    rm "$TEMPFILE"
}

# Menú principal
while true; do
    echo -e "${YELLOW}
╔════════════════════════════════════════════╗
║                MENÚ PRINCIPAL              ║
╠════════════════════════════════════════════╣
║ 1. Ping Scan (dispositivos activos)        ║
║ 2. Puertos comunes (escaneo rápido)        ║
║ 3. Escaneo completo de todos los puertos   ║
║ 4. Detección del sistema operativo (OS)    ║
║ 5. Detección de versiones de servicios     ║
║ 6. Escaneo agresivo (OS, servicios, tracer)║
║ 7. Buscar vulnerabilidades y puertos       ║
║ 8. Salir                                   ║
╚════════════════════════════════════════════╝
${RESET}"

    read -p ">> IP o dominio objetivo: " objetivo
    read -p ">> Selecciona una opción [1-8]: " opt

    case $opt in
        1)
            guardar_resultado
            echo -e "${CYAN}[*] Ejecutando ping scan...${RESET}"
            nmap -sn "$objetivo" $OUTPUT
            ;;
        2)
            guardar_resultado
            echo -e "${CYAN}[*] Escaneando puertos comunes...${RESET}"
            nmap -F "$objetivo" $OUTPUT
            ;;
        3)
            guardar_resultado
            echo -e "${CYAN}[*] Escaneo completo de puertos...${RESET}"
            nmap -p- "$objetivo" $OUTPUT
            ;;
        4)
            guardar_resultado
            echo -e "${CYAN}[*] Detectando sistema operativo...${RESET}"
            nmap -O "$objetivo" $OUTPUT
            ;;
        5)
            guardar_resultado
            echo -e "${CYAN}[*] Detectando servicios y versiones...${RESET}"
            nmap -sV "$objetivo" $OUTPUT
            ;;
        6)
            guardar_resultado
            echo -e "${CYAN}[*] Ejecutando escaneo agresivo...${RESET}"
            nmap -A "$objetivo" $OUTPUT
            ;;
        7)
            buscar_vulnerabilidades
            ;;
        8)
            echo -e "${GREEN}[+] Saliendo de NMAP-RECON ULTRA...${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Opción inválida.${RESET}"
            ;;
    esac

    echo -e "${CYAN}\nPresiona Enter para continuar...${RESET}"
    read
    clear
done
