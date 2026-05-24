{
  programs.zsh = {
    enable = true;
    enableCompletion = true; # Load NixOS-provided zsh completions (nix-zsh-completions)
    autosuggestions.enable = true; # Suggest previous commands as you type
    syntaxHighlighting.enable = true; # Highlight valid/invalid commands in real time
    # Oh My Zsh - plugin and theme framework for zsh
    # Note: zsh-completions are automatically installed via programs.zsh.enable
    # Ref: https://github.com/nix-community/nix-zsh-completions
    ohMyZsh = {
      enable = true;
      plugins = [ ];
    };
    # Shell initialization script - runs on every new shell session
    shellInit = ''
      # Print a welcome message with the distro name using cowsay and lolcat
      DISTRO=`sed -n -e /^NAME=/p /etc/os-release | cut -c 6-`
      EXCLAMATION="!!!"
      cowsay "Welcome to " ''$DISTRO''$EXCLAMATION | lolcat

      # Set Oh My Zsh custom directory (for custom themes and plugins)
      ZSH_CUSTOM=$HOME/.config/oh-my-zsh

      # Style for zsh-autosuggestions (dim grey, Solarized base01)
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#586e75"

      # Alt+E to edit the current command line in the default editor (usually $EDITOR)
      bindkey '^[e' edit-command-line

      # __copy_to_clipboard: shared clipboard helper
      # Wayland (Hyprland, Plasma on Wayland): wl-copy
      # X11 (Plasma on X11): xclip
      __copy_to_clipboard() {
          if [[ -n "$WAYLAND_DISPLAY" ]]; then
              wl-copy
          else
              xclip -selection clipboard
          fi
      }

      # copyfile: copy file contents to clipboard
      copyfile() {
          if [[ -z "''${1:-}" ]]; then
              echo "Usage: copyfile <file>"
              return 1
          fi
          if [[ ! -f "$1" ]]; then
              echo "Error: File not found: $1"
              return 1
          fi
          cat "$1"
          __copy_to_clipboard < "$1"
      }

      # copypath: copy current directory path to clipboard
      copypath() {
          local result=$(pwd)
          echo "''${result}"
          echo "''${result}" | __copy_to_clipboard
      }

      # nl: nurl wrapper to retrieve sha256 hash and revision for fetchFromGitHub
      # Ref: https://chitoku.jp/programming/bash-getopts-long-options/
      nl() {
          local option=""
          local url=""
          local rev=""

          __nl_usage() {
              cat <<EOM
      Usage: nl [-H|--hash|-r|--rev] <url> <rev>

      Arguments:
          <url>              URL to the repository to be fetched
          <rev>              The revision or reference to be fetched
      Options:
          -H, --hash         Show and copy to clipboard the hash value only
          -r, --rev          Show the rev value only
          -h, --help         Show this help message
      EOM
          }

          case "''${1:-}" in
          -h|--help)
              __nl_usage
              return 0
              ;;
          -H|--hash)
              option="hash"
              url="''${2}"
              rev="''${3}"
              ;;
          -r|--rev)
              option="rev"
              url="''${2}"
              rev="''${3}"
              ;;
          -*)
              echo "Error: Unknown option: ''${1}"
              __nl_usage
              return 1
              ;;
          "")
              echo "Error: No URL specified."
              __nl_usage
              return 1
              ;;
          *)
              option=""
              url="''${1}"
              rev="''${2}"
              ;;
          esac

          if [[ -z "$url" ]]; then
              echo "Error: No URL specified."
              __nl_usage
              return 1
          fi

          case "''${option}" in
          hash)
              local result=''$(nurl -H ''${url} ''${rev} 2> /dev/null)
              echo "''${result}"
              echo "''${result}" | __copy_to_clipboard
              ;;
          rev)
              echo "''${rev}"
              ;;
          *)
              local result=''$(nurl ''${url} ''${rev} 2> /dev/null)
              echo "''${result}"
              echo "''${result}" | __copy_to_clipboard
              ;;
          esac
      }

      # shell: zsh keyboard shortcuts cheatsheet
      shell() {
          local BOLD="\e[1m"
          local RESET="\e[0m"
          local CYAN="\e[36m"
          local YELLOW="\e[33m"
          local GREEN="\e[32m"
          local MAGENTA="\e[35m"
          local DIM="\e[2m"
          echo ""
          echo -e "''${BOLD}''${CYAN}╔══════════════════════════════════════════════════════╗''${RESET}"
          echo -e "''${BOLD}''${CYAN}║           zsh Keyboard Shortcuts Cheatsheet          ║''${RESET}"
          echo -e "''${BOLD}''${CYAN}╚══════════════════════════════════════════════════════╝''${RESET}"
          # ── Cursor Movement ──────────────────────────────────────────
          echo ""
          echo -e "''${BOLD}''${YELLOW}  Cursor Movement''${RESET}"
          echo -e "''${DIM}  ──────────────────────────────────────────────────────''${RESET}"
          echo ""
          echo -e "  ''${BOLD}Ctrl+A''${RESET}  Move to beginning of line"
          echo -e "  ''${DIM}  \$ git commit -m \"fix bug\"''${RESET}"
          echo -e "  ''${GREEN}    ^''${RESET}"
          echo -e "  ''${GREEN}    Ctrl+A moves here''${RESET}"
          echo ""
          echo -e "  ''${BOLD}Ctrl+E''${RESET}  Move to end of line"
          echo -e "  ''${DIM}  \$ git commit -m \"fix bug\"''${RESET}"
          echo -e "  ''${GREEN}                           ^''${RESET}"
          echo -e "  ''${GREEN}                           Ctrl+E moves here''${RESET}"
          echo ""
          echo -e "  ''${BOLD}Alt+F / Alt+B''${RESET}  Move forward / backward one word"
          echo -e "  ''${DIM}  \$ git commit -m \"fix bug\"''${RESET}"
          echo -e "  ''${GREEN}    ^   ^       ^  ^   ^   ''${RESET}"
          echo -e "  ''${GREEN}    Jump word by word''${RESET}"
          echo ""
          echo -e "  ''${BOLD}Alt+>''${RESET}  Insert history entry at cursor position"
          echo -e "  ''${DIM}  \$ git commit  \"fix bug\"''${RESET}"
          echo -e "  ''${GREEN}               ^''${RESET}"
          echo -e "  ''${GREEN}               Selected history entry is inserted here''${RESET}"
          # ── Text Editing ──────────────────────────────────────────
          echo ""
          echo -e "''${BOLD}''${YELLOW}  Text Editing''${RESET}"
          echo -e "''${DIM}  ──────────────────────────────────────────────────────''${RESET}"
          echo ""
          printf "  ''${BOLD}%-16s''${RESET} %s\n" "Ctrl+K" "Delete from cursor to end of line"
          echo -e "  ''${DIM}  \$ git commit -m \"fix bug\"''${RESET}"
          echo -e "  ''${DIM}            ^''${RESET}"
          echo -e "  ''${MAGENTA}            ├──────────────┤ ← deleted''${RESET}"
          echo ""
          printf "  ''${BOLD}%-16s''${RESET} %s\n" "Ctrl+U" "Delete entire line"
          echo -e "  ''${DIM}  \$ git commit -m \"fix bug\"''${RESET}"
          echo -e "  ''${MAGENTA}   ├───────────────────────┤ ← all deleted''${RESET}"
          echo ""
          printf "  ''${BOLD}%-16s''${RESET} %s\n" "Ctrl+T" "Swap the two characters before cursor"
          echo -e "  ''${DIM}  \$ git commit -m \"fxi bug\"''${RESET}"
          echo -e "  ''${DIM}                    ^^ cursor''${RESET}"
          echo -e "  ''${GREEN}  \$ git commit -m \"fix bug\"''${RESET}"
          echo -e "  ''${GREEN}                    ^^''${RESET}"
          echo ""
          printf "  ''${BOLD}%-16s''${RESET} %s\n" "Alt+T" "Swap the two words before cursor"
          echo -e "  ''${DIM}  \$ git commit -m \"fix bug\"''${RESET}"
          echo -e "  ''${DIM}    ^───^ cursor''${RESET}"
          echo -e "  ''${GREEN}  \$ commit git -m \"fix bug\"''${RESET}"
          echo -e "  ''${GREEN}    ^──────^''${RESET}"
          echo ""
          printf "  ''${BOLD}%-16s''${RESET} %s\n" "Ctrl+_" "Undo last edit"
          # ── Other ──────────────────────────────────────────────
          echo ""
          echo -e "''${BOLD}''${YELLOW}  Other''${RESET}"
          echo -e "''${DIM}  ──────────────────────────────────────────────────────''${RESET}"
          echo ""
          printf "  ''${BOLD}%-16s''${RESET} %s\n" "Ctrl+L" "Clear screen (history preserved)"
          printf "  ''${BOLD}%-16s''${RESET} %s\n" "Alt+E" "Edit current input in editor"
          echo ""
      }
    '';
    # Shell aliases
    shellAliases = {
      # Navigation
      ".." = "cd ../";
      "..." = "cd ../../";
      "...." = "cd ../../../";
      # Modern CLI replacements
      "ls" = "eza"; # eza: colorized ls with icons
      "ll" = "eza -l"; # Long listing format
      "tree" = "eza --tree"; # Directory tree view
      "size" = "fd --size"; # Find files sorted by size
      "diff" = "delta --side-by-side"; # Side-by-side diff with syntax highlighting
      "neofetch" = "fastfetch"; # fastfetch is the maintained successor to neofetch
      # Nix / NixOS
      # Ref: https://discourse.nixos.org/t/using-nix-develop-opens-bash-instead-of-zsh/25075
      "nix-develop" = "nix develop -c $SHELL"; # Open nix devShell in the current shell (zsh)
      "nixos" = "sudo nixos-rebuild switch --flake /etc/nixos#matrix --option sandbox false"; # Apply NixOS system config
      "gc" = "nix-collect-garbage --delete-old"; # Free disk space by deleting old Nix generations
      # Tools
      "net" = "speedtest"; # Ookla network speed test
      "clock" = "tty-clock -c -s"; # Centered terminal clock with seconds
      "tetris" = "bastet"; # Play Tetris in the terminal
      "cpu" = "s-tui"; # CPU stress test and monitoring TUI
      "music" = "cava"; # Terminal audio spectrum visualizer
    };
  };
}

