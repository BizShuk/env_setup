# VS Code

### settings.json

    keybindings.json settings.json snippets
    Windows:
        %APPDATA%\Code\User\settings.json
    macOS:
        $HOME/Library/Application Support/Code/User/settings.json
        $HOME/Library/Application Support/Code/User/settings.json
    Linux:
        $HOME/.config/Code/User/settings.json

### Extensions

To dump installed extensions:

    bin/vscode_extension_dump

To install extensions from `extensions.txt`:

    xargs -L 1 code --install-extension < bin/vscode/vscode_extension_list.txt
    xargs -L 1 agy-ide --install-extension < bin/vscode/agy_extension_list.txt
