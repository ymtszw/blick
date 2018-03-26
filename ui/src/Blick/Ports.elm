port module Blick.Ports exposing (lockScroll, unlockScroll, queryDOMOrigin, listenDOMOrigin)

import Blick.Type exposing (Field, DOMRect)


{-| Put 'is-clipped' class to document root. Idempotent.
-}
port lockScroll : () -> Cmd msg


{-| Remove 'is-clipped' class from document root
ONLY IF there are no '.modal-background' elements present.
-}
port unlockScroll : () -> Cmd msg


port queryDOMOrigin : String -> Cmd msg


port listenDOMOrigin : (DOMRect -> msg) -> Sub msg
