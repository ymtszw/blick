module Blick.Client exposing (listMaterials)

import Json.Decode exposing (field, list)
import Http as H exposing (..)
import Blick.Type exposing (..)


listMaterials : Cmd Msg
listMaterials =
    let
        dec =
            field "materials" <| list <| field "data" materialDecoder
    in
        H.send ListMaterials <| H.get "/api/materials" dec
