{ combinators, pkgs, ... }:
let
  inherit (combinators) add-runtime compose include-once;
in
{
  sig = "String -> Permission";
  doc = ''
    Add a simple message to the jail launch script, before the jail starts; if
    an emptry string is passed, no message is printed.

    This is primarily just an example of a custom combinator.
  '';
  impl =
    let
      bannerMsgHelperFunction = include-once "bannerMsgHelperFunction" (add-runtime ''
        function bannerMsg {
          local BANNER_MSG
          BANNER_MSG="$1"
          if [ -n "$BANNER_MSG" ] ; then
            ${pkgs.hello}/bin/hello -g "$BANNER_MSG"
          fi
        }
      '');
    in
    msg:
    compose [
      bannerMsgHelperFunction
      (add-runtime "bannerMsg \"${msg}\"")
    ];
}
