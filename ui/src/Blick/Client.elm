module Blick.Client exposing (listMaterials, materialsDictDecoder, getMaterial)

import Dict exposing (Dict)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Extra exposing ((|:))
import Http as H exposing (..)
import Blick.Type exposing (..)


listMaterials : Cmd Msg
listMaterials =
    let
        dec =
            D.map ListMaterials <|
                D.field "materials" materialsDictDecoder
    in
        H.send ClientRes <| H.get "/api/materials" dec


materialsDictDecoder : Decoder (Dict String Material)
materialsDictDecoder =
    D.map Dict.fromList <|
        D.list <|
            D.succeed (,)
                |: D.field "_id" D.string
                |: D.field "data" materialDecoder


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
