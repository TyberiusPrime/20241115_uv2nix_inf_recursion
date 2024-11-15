{
  description = "A basic flake using uv2nix";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/684a8fe32d4b7973974e543eed82942d2521b738";
    uv2nix.url = "github:/adisbladis/uv2nix";
    uv2nix.inputs.nixpkgs.follows = "nixpkgs";
    # uv2nix_hammer_overrides.url = "/project/builds/hammer_build_grimoire-elk_1.1.5/overrides";
    # uv2nix_hammer_overrides.inputs.nixpkgs.follows = "nixpkgs";
    pyproject-nix.url = "github:/nix-community/pyproject.nix";
    pyproject-nix.inputs.nixpkgs.follows = "nixpkgs";
    uv2nix.inputs.pyproject-nix.follows = "pyproject-nix";
  };
  outputs = {
    nixpkgs,
    uv2nix,
    #uv2nix_hammer_overrides,
    #pyproject-nix,
    ...
  }: let
    #inherit (nixpkgs) lib;
    lib = nixpkgs.lib // {match = builtins.match;};

    pyproject-nix = uv2nix.inputs.pyproject-nix;
    workspace = uv2nix.lib.workspace.loadWorkspace {workspaceRoot = ./.;};

    pkgs = import nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };

    defaultPackage = let
      # Generate overlay
      overlay = workspace.mkPyprojectOverlay {
        sourcePreference = "wheel";
      };
      #pyprojectOverrides = uv2nix_hammer_overrides.overrides_strict pkgs;
      pyprojectOverrides = final: prev: {
        # cloc = prev.cloc.overrideAttrs (old: {nativeBuildInputs = old.nativeBuildInputs ++ (final.resolveBuildSystems {setuptools = [];});});
        # mysqlclient = prev.mysqlclient.overrideAttrs (old: {nativeBuildInputs = old.nativeBuildInputs ++ (final.resolveBuildSystems {setuptools = [];});});
        # pandas = prev.pandas.overrideAttrs (old: {nativeBuildInputs = old.nativeBuildInputs ++ (final.resolveBuildSystems {setuptools = [];});});
        # numpy = prev.pandas.overrideAttrs (
        #   old: {
        #     nativeBuildInputs =
        #       old.nativeBuildInputs
        #       ++ (final.resolveBuildSystems {
        #         cython = [];
        #         oldest-supported-numpy = [];
        #         setuptools = [];
        #         wheel = [];
        #       });
        #   }
        # );
      };
      interpreter = pkgs.python39;
      spec = {
        uv2nix-hammer-app = [];
      };

      # Construct package set
      pythonSet' =
        (pkgs.callPackage pyproject-nix.build.packages {
          python = interpreter;
        })
        .overrideScope
        overlay;

      # Override host packages with build fixups
      pythonSet = pythonSet'.pythonPkgsHostHost.overrideScope pyprojectOverrides;
    in
      # Render venv
      pythonSet.mkVirtualEnv "test-venv" spec;
  in {
    packages.x86_64-linux.default = defaultPackage;
    # TODO: A better mkShell withPackages example.
  };
}
