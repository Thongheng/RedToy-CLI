
try:
    from prompt_toolkit import prompt
    from prompt_toolkit.completion import WordCompleter
    
    completer = WordCompleter(['hello', 'world', 'test'], ignore_case=True)
    # Just print the import success, don't actually prompt as it hangs non-interactive
    print("prompt_toolkit imported successfully")
except ImportError:
    print("prompt_toolkit not found")
