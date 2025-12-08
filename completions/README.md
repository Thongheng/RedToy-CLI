# Shell Completion Installation

Native shell completion for RedSploit (like nmap).

## For Zsh (Recommended for Linux)

### 1. Copy the completion file

```bash
sudo cp completions/_red /usr/share/zsh/site-functions/_red
```

Or for user-only install:
```bash
mkdir -p ~/.zsh/completion
cp completions/_red ~/.zsh/completion/_red

# Add to ~/.zshrc
fpath=(~/.zsh/completion $fpath)
autoload -U compinit && compinit
```

### 2. Reload shell

```bash
source ~/.zshrc
# Or open new terminal
```

### 3. Test

```bash
red -set <TAB>
```

You should see:
```
Completing variable
cred        -- Credentials in username:password format
domain      -- Domain name (default: .)
hash        -- NTLM hash (required if password not set)
interface   -- Network Interface
...
```

## For Bash

### 1. Install completion

```bash
# System-wide
sudo cp completions/red.bash /etc/bash_completion.d/red

# Or user-only
mkdir -p ~/.bash_completion.d
cp completions/red.bash ~/.bash_completion.d/red

# Add to ~/.bashrc
for f in ~/.bash_completion.d/*; do source $f; done
```

### 2. Reload

```bash
source ~/.bashrc
```

### 3. Test

```bash
red -set <TAB><TAB>
```

Should show: `cred domain hash interface lport password target username workspace`

## Verification

All shells should complete:
- `red -<TAB>` → Shows all flags
- `red -set <TAB>` → Shows variables
- `red --h<TAB>` → Completes to `--help`
