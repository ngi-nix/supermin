final: prev: 
(with builtins; seq ((hasAttr "inputs" prev) || throw "If you are calling this directly, make sure the overlays have an `inputs` attribute conforming to the flakes interface."))
(let
  packages = final.inputs.self.packages.${prev.system};
in {
  devShell.${prev.system} = final.supermin;

  supermin = prev.stdenv.mkDerivation {
   name = "supermin";

   src = final.inputs.supermin;

   configureFlags = [ "--disable-network-tests" ]; #TODO
   nativeBuildInputs = with prev.ocamlPackages; [ ocaml findlib ] ++ (with prev; [ autoreconfHook autoconf automake pkg-config cpio ]);
   buildInputs = [ prev.e2fsprogs prev.perl ]; 
   preBuild = ''
     patchShebangs ./src/bin2c.pl #needed during build, theres other stuff needed during tests too
     patchShebangs ./tests #TODO whats not covered by these patch?
     buildFlagsArray+=("init_LDFLAGS=-static -L${prev.glibc.static}/lib")
     '';
   doCheck = true;
   };
})
