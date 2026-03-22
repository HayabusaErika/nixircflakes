{
  description = "A modern IRC server (Ergo) managed by HayabusaErika";

  nixConfig = {
    extra-substituters = [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ];
    extra-trusted-public-keys = [ "tuna.tsinghua.edu.cn-1:jhS+7hR4gO+khF5C7yCJovQ8NvP1QKf5LWkzWqBpFz8=" ];
  };

  inputs = {
    nixpkgs.url = "git+https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git?ref=nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        irc-server = pkgs.ergochat;

        start-script = pkgs.writeShellScriptBin "start-irc-server" ''
          set -e
          # 绝对路径
          BASE_DIR=$(pwd)
          DATA_DIR="$BASE_DIR/data"
          CONFIG_DIR="$BASE_DIR/config"
          CONFIG_FILE="$CONFIG_DIR/ircd.yaml"

          mkdir -p "$DATA_DIR" "$CONFIG_DIR"

          if [ ! -f "$CONFIG_FILE" ]; then
            echo "错误: 未找到配置文件 $CONFIG_FILE"
            # 指向 nixpkgs 中真实的示例配置路径
            EXAMPLE_CONF="${irc-server}/share/ergochat/default.yaml"
            if [ -f "$EXAMPLE_CONF" ]; then
                echo "正在从 $EXAMPLE_CONF 复制默认配置..."
                cp "$EXAMPLE_CONF" "$CONFIG_FILE"
                # Ergo 默认配置通常是只读的，赋予写权限以便用户修改
                chmod +w "$CONFIG_FILE"
                echo "请编辑 $CONFIG_FILE 后重新运行 (需配置服务器域名和存储路径)"
            else
                echo "无法在存储路径中找到示例配置，请手动创建。"
            fi
            exit 1
          fi

          echo "正在启动 Ergo IRC Server..."
          exec ${irc-server}/bin/ergo run --conf "$CONFIG_FILE"
        '';
      in
      {
        # 开发环境
        devShells.default = pkgs.mkShell {
          buildInputs = [ irc-server pkgs.coreutils ];
          shellHook = ''
            echo "IRC 开发环境已就绪"
            echo "命令列表: "
            echo "  ergo             - 直接运行二进制"
            echo "  start-irc-server - 使用本地配置启动"
          '';
        };

        # 使用 nix run .#start 启动
        apps.start = {
          type = "app";
          program = "${start-script}/bin/start-irc-server";
        };

        # 默认构建包
        packages.default = pkgs.symlinkJoin {
          name = "irc-server-env";
          paths = [ irc-server start-script ];
        };
      }
    );
}
