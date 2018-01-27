module Blick.Client exposing (listMaterials)

import Json.Decode as D
import Json.Decode.Extra exposing ((|:))
import Http as H exposing (..)
import Blick.Type exposing (..)


listMaterials : Cmd Msg
listMaterials =
    let
        dec =
            D.field "materials" <|
                D.list <|
                    D.succeed (,)
                        |: D.field "_id" idDecoder
                        |: D.field "data" materialDecoder
    in
        H.send ListMaterials <| H.get "/api/materials" dec
