# ⚡️ BreachProtocol

> Automatización del reconocimiento inicial para máquinas de HackTheBox y otros entornos CTF.

## Descripción

BreachProtocol (`BPv3.sh`) es un script en Bash pensado para quitar de en medio la parte repetitiva del reconocimiento inicial en CTF: crear la estructura de carpetas de cada máquina, gestionar la conexión/desconexión de la VPN y lanzar un escaneo nmap completo (TCP o UDP), generando automáticamente los reportes.

## Objetivo

Reducir el tiempo "muerto" al empezar una máquina de HTB (o similar): un único comando crea el entorno de trabajo, conecta la VPN si hace falta y lanza el escaneo de puertos con una configuración pensada para fiabilidad y evasión básica (`-T2`, `--source-port 53`, reintentos, etc).

## Requisitos

- `nmap`
- `openvpn`
- `xsltproc` (opcional, para el reporte HTML; sin él el escaneo se completa igual)
- Permisos sudo (`nmap` y `openvpn` se ejecutan con `sudo`)
- Archivos `.ovpn` ubicados en `/home/dreddsec/Downloads/` (ruta y usuario quedan fijados dentro del script, ver "Limitaciones conocidas")

## Instalación

```bash
git clone https://github.com/DreddSec/BreachProtocol.git
cd BreachProtocol
chmod +x BPv3.sh
```

## Uso

```bash
./BPv3.sh [OPCIONES]
```

| Flag | Argumento   | Descripción                                                           |
|------|-------------|-----------------------------------------------------------------------|
| `-f` | FOLDER_NAME | Nombre de la carpeta de trabajo para la máquina                       |
| `-h` | HOST/IP     | IP o host objetivo                                                    |
| `-c` | —           | Conecta a la VPN antes de escanear (selección interactiva del `.ovpn`)|
| `-d` | —           | Desconecta la VPN y termina (ignora el resto de flags)                |
| `-t` | —           | Escaneo TCP, todos los puertos (opción por defecto)                   |
| `-u` | —           | Escaneo UDP, todos los puertos                                        |

## Ejemplos

```bash
# Conectar VPN, crear carpeta y lanzar escaneo TCP completo
./BPv3.sh -f Forest -h 10.10.10.161 -c -t

# Escaneo UDP sin tocar la VPN (asume que ya está conectada)
./BPv3.sh -f Forest -h 10.10.10.161 -u

# Cortar la VPN
./BPv3.sh -d
```

## Flujo interno

1. Parseo de flags con `getopts`.
2. Si `-d`: desconecta la VPN (mata el proceso `openvpn`) y sale.
3. Si hay `-c` + `-f` + `-h`: crea la estructura de carpetas, conecta la VPN y lanza el escaneo.
4. Si solo hay `-f` + `-h` (sin `-c`): crea la carpeta si no existe y lanza el escaneo directamente, asumiendo que la VPN ya está activa.
5. Si falta `-f` o `-h`: muestra la ayuda y sale del programa.

`Ctrl+C` está capturado (`trap SIGINT SIGTERM`): mata los procesos de `nmap` en curso y sale de forma controlada.

## Estructura de carpetas generada

```
<machine_name>/
├── scan/       # Resultados de nmap (.nmap, .xml, .gnmap) y reporte HTML
├── exploits/   # Exploits / PoCs de la máquina
└── content/    # Notas, capturas, credenciales, etc.
```

## Detalle del escaneo

**TCP** (`-t`, por defecto):
```
nmap -sSV -p- -vv -Pn -n -T2 --min-rate 3000 --stats-every=5s --max-retries 3 --source-port 53 -oA <ruta>
```

**UDP** (`-u`):
```
nmap -sU -p- -vv -n -T2 --min-rate 3000 --stats-every=5s --max-retries 3 --source-port 53 -oA <ruta>
```

Justificación de las flags utilizadas:

- `-p-` → escanea los 65535 puertos, nada de top-1000.
- `-sSV` → SYN scan + detección de versión de servicio en un solo paso.
- `-Pn` → se salta el host discovery previo (evita falsos negativos en máquinas que filtran ICMP).
- `-T2` → timing "polite", prioriza fiabilidad sobre velocidad.
- `--min-rate 3000` → pone un suelo de velocidad para que `-T2` no se eternice en `-p-`.
- `--source-port 53` → origina los paquetes desde el puerto 53, útil contra firewalls que confían ciegamente en tráfico "DNS".
- `-oA` → exporta el resultado en los tres formatos de nmap (normal, XML, grepable) a la vez.

Si `xsltproc` está disponible y el XML del escaneo se completó correctamente, se genera además un reporte HTML legible a partir del XSL propio de nmap.


## Aviso

Herramienta pensada exclusivamente para entornos autorizados (HackTheBox, TryHackMe, laboratorios propios). No la uses contra objetivos sin autorización explícita.
