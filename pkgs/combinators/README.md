# how to use custom combinators

```nix
# in `../jailed.nix`
   jail = lib.jail.extend {
     pkgs = final;
     additionalCombinators = combinators: {
       banner =
         (import ./combinators/banner.nix {
           inherit combinators lib;
           pkgs = final;
         }).impl;
     };
   };
# ...then just use like any other built-in combinator
```
