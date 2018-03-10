module Blick.Client exposing (listMaterials, getMaterial, updateMaterialField)

import Json.Encode as E exposing (Value)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Extra exposing ((|:))
import Http as H exposing (Request)
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
getMaterial id_ =
    H.send ClientRes <|
        H.get
            ("/api/materials/" ++ id_)
            (D.map GetMaterial singleMaterialDecoder)


singleMaterialDecoder : Decoder ( String, Material )
singleMaterialDecoder =
    D.succeed (,)
        |: D.field "_id" D.string
        |: D.field "data" materialDecoder


updateMaterialField : String -> Field -> Cmd Msg
updateMaterialField id_ { name_, value_ } =
    H.send ClientRes <|
        put
            ("/api/materials/" ++ id_ ++ "/" ++ name_)
            (D.map UpdateMaterialField singleMaterialDecoder)
            (E.object [ ( "value", E.string value_ ) ])


put : String -> Decoder a -> Value -> Request a
put url dec value =
    H.request
        { method = "PUT"
        , headers = []
        , url = url
        , body = H.jsonBody value
        , expect = H.expectJson dec
        , timeout = Nothing
        , withCredentials = False
        }
