module Blick.Client exposing (listMaterials, getMaterial)

import Json.Decode as D
import Json.Decode.Extra exposing ((|:))
import Http as H exposing (..)
import Blick.Type exposing (..)


listMaterials : Cmd Msg
listMaterials =
    let
        dec =
            D.map ListMaterials <|
                D.field "materials" <|
                    D.dict (D.field "data" materialDecoder)
    in
        H.send ClientRes <| H.get "/api/materials" dec


getMaterial : String -> Cmd Msg
getMaterial id =
    let
        dec =
            D.map GetMaterial <|
                D.succeed (,)
                    |: D.field "_id" D.string
                    |: D.field "data" materialDecoder
    in
        H.send ClientRes <| H.get ("/api/materials/" ++ id) dec
