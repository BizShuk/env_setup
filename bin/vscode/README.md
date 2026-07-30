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

    env_setup dump vscode
    env_setup dump antigravity

To install extensions from `extensions.txt`:

    xargs -L 1 code --install-extension < bin/vscode/vscode_extension_list.txt
    xargs -L 1 agy-ide --install-extension < bin/vscode/agy-ide_extension_list.txt
