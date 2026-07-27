# <img width="120" height="124" alt="HACKS" src="https://github.com/user-attachments/assets/3e0b8e67-cb80-4c94-8f6d-02c54a622a77" width="40" height="40"> BreachProtocol 

> Automatización del reconocimiento inicial para máquinas de HackTheBox y otros entornos CTF.

## Descripción

BreachProtocol es un script en Bash pensado para eliminar la parte repetitiva del reconocimiento inicial en CTF: crea la estructura de carpetas de la máquina, gestiona la conexión y desconexión de la VPN y lanza un escaneo completo de puertos con Nmap, generando reportes automáticos.

## 🎯 Objetivo

Reducir el tiempo perdido al empezar una máquina de HTB o similar: con un único comando puedes preparar el entorno, conectar la VPN si hace falta y lanzar el escaneo con una configuración pensada para fiabilidad y evasión básica.

## ✅ Requisitos

- `nmap`
- `openvpn`
- `xsltproc` (opcional, para generar el reporte HTML)
- Permisos de `sudo`
- Archivos `.ovpn` ubicados en `~/Downloads/`

## 🚀 Instalación rápida

```bash
git clone https://github.com/DreddSec/BreachProtocol.git
cd BreachProtocol
chmod +x BreachProtocolv2.sh
sudo ln -sf "$PWD/BreachProtocolv2.sh" /usr/local/bin/bp
chmod +x /usr/local/bin/bp
```

Si tu shell no reconoce `/usr/local/bin` de forma automática, añade esta línea a tu configuración:

```bash
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Con eso ya podrás ejecutarlo directamente como:

```bash
bp
```

## 🧭 Uso

```bash
bp [OPCIONES]
```

| Flag | Argumento | Descripción |
|------|-----------|-------------|
| `-f` | `FOLDER_NAME` | Nombre de la carpeta de trabajo para la máquina |
| `-h` | `HOST/IP` | IP o host objetivo |
| `-c` | — | Conecta a la VPN antes de escanear usando un archivo `.ovpn` interactivo |
| `-d` | — | Desconecta la VPN y termina |
| `-t` | — | Escaneo TCP completo (opción por defecto) |
| `-u` | — | Escaneo UDP completo |

## 🔎 Ejemplos

```bash
# Conectar VPN, crear carpeta y lanzar escaneo TCP completo
bp -f Forest -h 10.10.10.161 -c -t

# Escaneo UDP sin tocar la VPN (asume que ya está conectada)
bp -f Forest -h 10.10.10.161 -u

# Cortar la VPN
bp -d
```

## ⚙️ Flujo interno

1. Se parsean las flags con `getopts`.
2. Si se usa `-d`, se desconecta la VPN y termina.
3. Si se combina `-c` con `-f` y `-h`, se crea la estructura de carpetas, se conecta la VPN y se lanza el escaneo.
4. Si solo se pasan `-f` y `-h`, se crea la carpeta si hace falta y se escanea directamente, asumiendo que la VPN ya está activa.
5. Si falta `-f` o `-h`, se muestra la ayuda y se sale del programa.

`Ctrl+C` está capturado con `trap SIGINT SIGTERM`: mata los procesos de `nmap` en curso y sale de forma controlada.

## 📁 Estructura de carpetas generada

```text
<machine_name>/
├── scan/       # Resultados de nmap (.nmap, .xml, .gnmap) y reporte HTML
├── exploits/   # Exploits / PoCs de la máquina
└── content/    # Notas, capturas, credenciales, etc.
```

## 🔬 Detalle del escaneo

**TCP** (`-t`, por defecto):

```bash
nmap -sSV -p- -vv -Pn -n -T2 --min-rate 3000 --stats-every=5s --max-retries 3 --source-port 53 -oA <ruta>
```

**UDP** (`-u`):

```bash
nmap -sU -p- -vv -Pn -n -T2 --min-rate 3000 --stats-every=5s --max-retries 3 --source-port 53 -oA <ruta>
```

Justificación de las flags utilizadas:

- `-p-` → escanea los 65535 puertos, nada de top-1000.
- `-sSV` → SYN scan + detección de versión de servicio en un solo paso.
- `-Pn` → se salta el host discovery previo para evitar falsos negativos en máquinas que filtran ICMP.
- `-T2` → timing "polite", priorizando fiabilidad sobre velocidad.
- `--min-rate 3000` → pone un suelo de velocidad para que `-T2` no se eternice en `-p-`.
- `--source-port 53` → origina los paquetes desde el puerto 53, útil contra firewalls que confían en tráfico DNS.
- `-oA` → exporta los resultados en los tres formatos de Nmap a la vez.

Si `xsltproc` está disponible y el XML del escaneo se completó correctamente, se genera además un reporte HTML legible a partir del XSL propio de Nmap.

## ⚠️ Aviso

Herramienta pensada exclusivamente para entornos autorizados (HackTheBox, TryHackMe, laboratorios propios). No la uses contra objetivos sin autorización explícita.
