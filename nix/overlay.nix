final: prev: 
(with builtins; seq ((hasAttr "inputs" prev) || throw "If you are calling this directly, make sure the overlays have an `inputs` attribute conforming to the flakes interface."))
(let
  packages = final.inputs.self.packages.${prev.system};
in {
  devShell = final.supermin;

  supermin = prev.stdenv.mkDerivation {
   name = "supermin";

   src = builtins.filterSource (path: type:
     # changed nix files don't affect the package build
     path != "nix" &&
     builtins.match ".+\\.nix$" path == null
   ) final.inputs.self;

#   configureFlags = [ "--disable-network-tests" ]; #TODO
   nativeBuildInputs = with prev.ocamlPackages; [ ocaml findlib ] ++ (with prev; [ makeWrapper autoreconfHook autoconf automake pkg-config ]);
   buildInputs = [ prev.e2fsprogs prev.perl ];
   propagatedBuildInputs = with prev; [ nix cpio ];
   preBuild = ''
     patchShebangs ./src/bin2c.pl #needed during build, theres other stuff needed during tests too
     patchShebangs ./tests #TODO whats not covered by these patch?
     buildFlagsArray+=("init_LDFLAGS=-static -L${prev.glibc.static}/lib")
     '';
   postInstall = ''
     bzImage=${prev.linux_latest}/bzImage
     modules=$(echo ${prev.linux_latest}/lib/modules/*/)
     wrapProgram $out/bin/supermin
     #TODO omg uznfuck this whole section
     echo -e "bzImage=$bzImage\nmodules=$modules\n"'export SUPERMIN_KERNEL=''${SUPERMIN_KERNEL:-$bzImage}\nexport SUPERMIN_MODULES=''${SUPERMIN_MODULES:-$modules}\n' | cat <(head -n1 $out/bin/supermin) - $out/bin/supermin | ${prev.moreutils}/bin/sponge $out/bin/supermin
     '';
   preCheck = ''
     bzImage=${prev.linux_latest}/bzImage
     modules=$(echo ${prev.linux_latest}/lib/modules/*/)
     wrapProgram $(realpath src/supermin)
     #TODO omg uznfuck this whole section
     echo -e "bzImage=$bzImage\nmodules=$modules\n"'export SUPERMIN_KERNEL=''${SUPERMIN_KERNEL:-$bzImage}\nexport SUPERMIN_MODULES=''${SUPERMIN_MODULES:-$modules}\n' | cat <(head -n1 src/supermin) - src/supermin | ${prev.moreutils}/bin/sponge src/supermin
     '';

#   doCheck = true;
   };
})

