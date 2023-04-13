{
  description = "zooenct/elixir-ls";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-22.11-darwin";
    nixpkgs-unstable.url = github:nixos/nixpkgs/nixpkgs-unstable;

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs-unstable, flake-utils, ... } @ args: flake-utils.lib.eachSystem ["aarch64-darwin" "x86_64-darwin" "x86_64-linux"] (system: let
    pkgs = import nixpkgs-unstable { inherit system; };

    erlangVersion = "erlangR25";
    erlang = pkgs.beam.interpreters.${erlangVersion};

    elixirVersion = "elixir_1_14";
    elixir = pkgs.beam.packages.${erlangVersion}.${elixirVersion};

    inherit (pkgs.lib) optional optionals;
  in rec {
    devShells.default = nixpkgs-unstable.legacyPackages.${system}.mkShell {
      buildInputs = [
        erlang
        elixir
      ];

      shellHook = ''
        export MIX_HOME="$PWD/.nix/mix"
        export MIX_BUILD_ROOT="$PWD/.nix/mix/_build"
        export MIX_DEPS_PATH="$PWD/.nix/mix/deps"
        export HEX_HOME="$PWD/.nix/hex"
        mkdir -p "$MIX_HOME" "$MIX_BUILD_ROOT" "$MIX_DEPS_PATH" "$HEX_HOME"

        mix local.rebar --if-missing --force
        mix local.hex --if-missing --force

        export PATH="$MIX_HOME/bin:$MIX_HOME/escripts:$HEX_HOME/bin:$PATH"
        export ERL_AFLAGS="-kernel shell_history enabled -kernel shell_history_path '\"$PWD/.nix/.erlang-history\"'";

        export ELIXIR_LS_PATH="/Users/$USER/.vscode/elixir-ls-release"

        mix deps.get
        MIX_ENV=prod mix compile
        MIX_ENV=prod mix elixir_ls.release -o "$ELIXIR_LS_PATH"
      '';
    };
  });
}
