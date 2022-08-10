{ config, lib, pkgs, inputs ? builtins.throw "Expected an inputs argument that corresponds to flake conventions", ... }: #TODO not sure this default arg is a good solution to this
let
  packages = inputs.self.packages.${pkgs.system};
in {
}
