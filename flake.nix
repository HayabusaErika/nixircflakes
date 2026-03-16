# file: flake.nix
{
  description = "A modern IRC server (Ergo) managed by HayabusaErika";

  # 中国大陆镜像配置（清华源）
  nixConfig = {
    extra-substituters = [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ];
    extra-trusted-public-keys = [ "tuna.tsinghua.edu.cn-1:jhS+7hR4gO+khF5C7yCJovQ8NvP1QKf5LWkzWqBpFz8=" ];
  };

  inputs = {
    # 使用清华镜像的 nixpkgs 稳定分支（nixos-24.11）
    nixpkgs.url = "https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        irc-server = pkgs.ergochat;  
        # Ergo 在 nixpkgs 中的属性名其实是 ergochat
        #不是Ergo！

        # 启动脚本
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
