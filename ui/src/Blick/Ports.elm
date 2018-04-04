port module Blick.Ports exposing (lockScroll, unlockScroll, queryEditorDOMRect, listenEditorDOMRect)

import Blick.Type exposing (..)


{-| Put 'is-clipped' class to document root. Idempotent.
-}
port lockScroll : () -> Cmd msg


{-| Remove 'is-clipped' class from document root
ONLY IF there are no '.modal-background' elements present.
-}
port unlockScroll : () -> Cmd msg


queryEditorDOMRect : MatId -> Field -> Selector -> Cmd msg
queryEditorDOMRect (MatId id) field (Selector sel) =
    queryEditorDOMRectPort ( id, fieldForPort field, sel )


{-| `DirtyValue` is 3-state Tagged Union, which cannot go thru ports.

We only take `prev` field (`Maybe String`) and pass it thru ports,
and supplment `edit` field with `UnTouched` after coming back from port subs.

-}
type alias FieldThruPort =
    { name_ : String
    , value_prev : Maybe String
    }


fieldForPort : Field -> FieldThruPort
fieldForPort { name_, value_ } =
    { name_ = name_, value_prev = value_.prev }


port queryEditorDOMRectPort : ( String, FieldThruPort, String ) -> Cmd msg


listenEditorDOMRect : (MatId -> Field -> DOMRect -> msg) -> Sub msg
listenEditorDOMRect toMsg =
    listenEditorDOMRectSub <|
        \( rawMatId, fieldThruPort, domRect ) ->
            toMsg (MatId rawMatId) (fieldFromPort fieldThruPort) domRect


fieldFromPort : FieldThruPort -> Field
fieldFromPort { name_, value_prev } =
    Field name_ (Editable value_prev UnTouched)


port listenEditorDOMRectSub : (( String, FieldThruPort, DOMRect ) -> msg) -> Sub msg
