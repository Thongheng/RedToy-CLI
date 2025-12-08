# Bash completion for red command

_red_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Main options
    opts="-h --help --interactive -T --target -U --user -D --domain -H --hash -i --infra -w --web -f --file -set"
    
    case "${prev}" in
        -T|--target|-U|--user|-D|--domain|-H|--hash)
            # No completion for these (user input)
            return 0
            ;;
        *)
            ;;
    esac
    
    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}

complete -F _red_completion red
