# file: flake.nix
{
  description = "A modern IRC server (Ergo) managed by HyaabusaErika";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        irc-server = pkgs.ergochat;  
        # Ergo 在 nixpkgs 中的属性名不出以外的是 ergochat

        # 启动脚本试一试看看
        start-script = pkgs.writeShellScriptBin "start-irc-server" ''
          set -e
          DATA_DIR="./data"
          CONFIG_FILE="./config/ircd.yaml"
          mkdir -p "$DATA_DIR"

          # 如果配置文件不存在就从默认配置复制一份
          if [ ! -f "$CONFIG_FILE" ]; then
            echo "No config found. Copying default config to $CONFIG_FILE"
            cp ${irc-server}/ircd.yaml "$CONFIG_FILE"
            echo "Please edit $CONFIG_FILE and set appropriate values (especially server name, TLS, etc.)"
            exit 1
          fi

          exec ${irc-server}/bin/ergo run --conf "$CONFIG_FILE"
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [ irc-server pkgs.coreutils ];
          shellHook = ''
            echo "IRC Development Environment"
            echo "Available commands: ergo, start-irc-server"
          '';
        };

        apps.start = {
          type = "app";
          program = "${start-script}/bin/start-irc-server";
        };

        packages.default = pkgs.symlinkJoin {
          name = "irc-server-env";
          paths = [ irc-server start-script pkgs.coreutils pkgs.bash ];
        };
      }
    );
}
