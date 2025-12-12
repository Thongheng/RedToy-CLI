# RedSploit

Red Team penetration testing CLI tool with interactive shell and automation capabilities.

## Features

- 🔧 **Interactive Shell** - Full-featured console with tab completion
- 🚀 **Quick CLI Mode** - Run commands directly from terminal
- 🎯 **Module System** - Infrastructure, Web, and File modules
- ⚡ **Shell Completion** - Native bash/zsh completion support
- 📝 **Variable Management** - Session-based environment variables

## Quick Start

### Installation

```bash
git clone https://github.com/Thongheng/RedSploit.git
cd RedSploit
sudo ./install.sh
```

This will:
- Install `red` command to `/usr/bin`
- Setup shell completion automatically
- Make the tool accessible from anywhere

**Manual install (no sudo):**
```bash
chmod +x red.py
./red.py
```

### Usage

**Interactive Mode:**
```bash
red
# or with preset values
red -set -T 10.10.10.10
```

**CLI Mode:**
```bash
red -T 10.10.10.10 -U admin:pass123 -i nmap -p-
red -w -T example.com -gobuster
red -f -T 10.10.10.10 -download /etc/passwd
```

**Command Flags:**

When running commands, you can use these flags to modify behavior:

| Flag | Description | Example |
|------|-------------|---------|
| `-c` / `--copy` | Copy command to clipboard without executing | `red -T 10.10.10.10 -w -dir_ferox -c` |
| `-p` / `--preview` | Preview the command without executing | `red -T 10.10.10.10 -i -nmap -p` |
| `-e` / `--edit` | Edit the command before execution | `red -T 10.10.10.10 -w -nuclei -e` |
| `-auth` | Use credentials from session (interactive mode only) | `smbclient -auth` |

**Set Variables:**
```bash
red -T 10.10.10.10      # Set target
red -U admin:pass       # Set user credentials (auto-splits to username:password)
red -D WORKGROUP        # Set domain
red -H <ntlm_hash>      # Set NTLM hash
```

## Available Modules

| Flag | Module | Description |
|------|--------|-------------|
| `-i` | infra | Infrastructure enumeration (nmap, rustscan) |
| `-w` | web | Web reconnaissance (gobuster, nuclei, etc.) |
| `-f` | file | File operations (download, upload, servers) |

## Variables

| Name | Description |
|------|-------------|
| `target` | Target IP/hostname/CIDR |
| `user` | User credentials (auto-splits on `:` to username and password) |
| `username` | Username (auto-set from user variable) |
| `password` | Password (auto-set from user variable) |
| `domain` | Domain name (default: .) |
| `hash` | NTLM hash (alternative to password) |
| `interface` | Network interface |
| `lport` | Local port for reverse shells (default: 4444) |
| `workspace` | Workspace name (default: default) |

## Credential Handling

RedSploit supports flexible credential management with automatic splitting and mode-based authentication:

**Auto-Split Credentials:**
```bash
# Set username and password in one command
red -set user admin:password123
# Automatically creates: username=admin, password=password123

# Or set username only
red -set user admin
```

**Mode-Based Authentication:**

- **CLI Mode**: Automatically uses credentials when available
  ```bash
  # With credentials - auto-applied
  red -T 10.10.10.10 -U admin:pass -i -smb-c
  
  # Without credentials - uses NULL session
  red -T 10.10.10.10 -i -smb-c
  ```

- **Interactive Mode**: Defaults to NULL session, use `-auth` flag to apply credentials
  ```bash
  red -i
  > set user admin:password123
  > use infra
  
  # NULL session (default)
  > smbclient
  
  # With credentials (use -auth flag)
  > smbclient -auth
  ```

## Examples

```bash
# Quick nmap scan
red -T 10.10.10.10 -i -nmap

# Web directory enumeration
red -T example.com -w -dir_ffuf

# SMB enumeration with credentials (CLI auto-auth)
red -T 10.10.10.10 -U admin:pass -i -smb-c

# SMB enumeration without credentials (NULL session)
red -T 10.10.10.10 -i -smb-c

# Interactive mode with credentials
red -i
> set target 10.10.10.10
> set user admin:password
> use infra
> smbclient -auth  # Use credentials
> smbmap           # NULL session (default)
```

## License

MIT
