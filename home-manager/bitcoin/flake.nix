{
  description = "Bitcoin development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-darwin" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };
        isLinux = pkgs.stdenv.isLinux;
        binDirs = [ "./build/bin" "./build/bin/qt" ];

        # Common dependencies for both platforms
        commonNativeBuildInputs = with pkgs; [
          byacc
          ccache
          clang-tools_19
          clang_19
          cmake
          gdb
          hexdump
          mold-wrapped
          ninja
          pkg-config
          python312
          python312Packages.autopep8
          python312Packages.flake8
          python312Packages.mypy
          python312Packages.vulture
          python312Packages.pyzmq
          python312Packages.requests
        ];

        # Linux-specific dependencies
        linuxNativeBuildInputs = with pkgs; [
          libsystemtap
          linuxPackages.bcc
          linuxPackages.bpftrace
        ];

        # Combine dependencies based on platform
        nativeBuildInputs = commonNativeBuildInputs ++ (if isLinux then linuxNativeBuildInputs else [ ]);

        # Common runtime dependencies
        buildInputs = with pkgs; [
          boost
          libevent
          sqlite
          capnproto
          db4
          qrencode
          zeromq
          qt6.qtbase
          qt6.qttools
        ];

        # Platform-specific shell hook
        shellHook = ''
          # Use clang by default
          export CC=clang
          export CXX=clang++

          # Use Ninja generator 🥷
          export CMAKE_GENERATOR="Ninja"

          # Use mold linker 🦠
          export LDFLAGS="-fuse-ld=mold"

          # Add build dirs to PATH
          export PATH=$PATH:${builtins.concatStringsSep ":" binDirs}

          ${if isLinux then ''
            # Linux-specific settings
            BCC_EGG=${pkgs.linuxPackages.bcc}/${pkgs.python3.sitePackages}/bcc-${pkgs.linuxPackages.bcc.version}-py3.${pkgs.python3.sourceVersion.minor}.egg
            if [ -f $BCC_EGG ]; then
              export PYTHONPATH="$PYTHONPATH:$BCC_EGG"
            else
              echo "Warning: The bcc egg $BCC_EGG does not exist. Skipping bcc PYTHONPATH setup."
            fi
          '' else ''
          ''}
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          inherit nativeBuildInputs buildInputs shellHook;
        };
      }
    );
}
