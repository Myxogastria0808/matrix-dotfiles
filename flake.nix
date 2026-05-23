{
  description = "Matrix server on Incus NixOS container";

  inputs = {
    # Package collection - nixpkgs-unstable for latest packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # NixVim configuration from a separate external flake
    # Ref: https://github.com/Myxogastria0808/nix-flakes-nixvim
    nixvimConfig = {
      url = "github:Myxogastria0808/nix-flakes-nixvim/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs:
    let
      systems = "x86_64-linux"; # Target architecture
      username = "hello"; # Your Linux username (home directory will be /home/hello)
      containerName = "matrix"; # Name of the Incus container

      # Nixpkgs instance with allowUnfree — shared by both NixOS and home-manager
      pkgs = import inputs.nixpkgs {
        system = systems;
        config.allowUnfree = true;
      };
    in
    {
      # ── NixOS ─────────────────────────────────────────────────────────────────
      # Replace "nixos" with your hostname if different from the default
      nixosConfigurations = {
        ${inputs.containerName} = inputs.nixpkgs.lib.nixosSystem {
          inherit pkgs;
          # Merge base config, app modules, and nixvim from the external flake
          modules = [
            # NixOS base system configuration
            ./nixos/configuration.nix
            # NixOS application and tool modules
            ./modules/apps.nix
          ];
          specialArgs = {
            inherit inputs;
            inherit username;
            inherit containerName;
          };
        };
      };
    };

}

