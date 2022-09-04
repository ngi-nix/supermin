{
  description = "TODO";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

#    supermin.url = "github:libguestfs/supermin";
#    supermin.url = "path:" + (builtins.unsafeDiscardStringContext (builtins.toString ./.));
    supermin.url = "path:./.";
#    supermin.url = "path:/bakery7/oven7/ephemeral/work/SoN-2022/supermin2";
    supermin.flake = false;
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    # System types to support.
    supportedSystems = ["x86_64-linux"];
    # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
    genSystems = nixpkgs.lib.genAttrs supportedSystems;
    pkgsFor = nixpkgs.legacyPackages;

    resolveOverlays = first: overlays: with nixpkgs.lib; let
      # Passing inputs here means overlays can be called with the standard signature
      # but still be parametrized with flakes, maintaining composability. 
      overlay' = flip (composeManyExtensions ([ (final: prev: { inherit inputs; }) ] ++ overlays));
      # We don't to expose all of nixpkgs in the resulting attrset (like with .extend()), #TODO why not, or a .pkgs?
      # so we take the fixpoint ourselves
      attrs = fix (overlay' first);
    in builtins.removeAttrs attrs [ "inputs" ]; #TODO I don't like doing it this way but I don't have a better idea how to keep the interface clean.

    # TODO something is happening with argument processing, if I dont add the pkgs argument here it doesnt get passed to the module and breaks
    # applyModuleArgsIfFunction /nix/store/43m6mis3zbnq5q9rw2yklnf6398p1x93-source/flake.nix
    callModule = modPath: {pkgs, ...}@args: import modPath (args // { inherit inputs; });

    mkSystem = system: modules: nixpkgs.lib.nixosSystem { inherit system modules; }; # TODO does the system argument make sense?
  in {
    overlays.default = import ./nix/overlay.nix;

    # Expose the module for use as an input in another flake
    nixosModules.module = callModule ./nix/module.nix;

    # Provide some packages for selected system types.
    packages = genSystems (system:
      let attrs = resolveOverlays pkgsFor.${system} [ (import ./nix/overlay.nix) ];
      in attrs
    );

    # Tests run by 'nix flake check' and by Hydra.
    checks = genSystems (system: 
      import ./nix/checks.nix {
        inherit self nixpkgs;
        pkgs = pkgsFor.${system};
      }
    );

    # We use the default devShell behaviour
    # devShells = ...

    # System configuration for a nixos-container local dev deployment #TODO is there a local automated way to run an end-to-end test on this?
    nixosConfigurations.container = mkSystem "x86_64-linux" [ (callModule ./nix/container.nix) ]; # TODO does that system argument make sense?
  };
}

