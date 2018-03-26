module Blick.Client exposing (listMaterials, getMaterial, updateMaterialField, listMembers)

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
                    matDictDecoder
    in
        H.send ClientRes <| H.get "/api/materials" dec


getMaterial : MatId -> Cmd Msg
getMaterial (MatId id_) =
    H.send ClientRes <|
        H.get
            ("/api/materials/" ++ id_)
            (D.map GetMaterial singleMaterialDecoder)


singleMaterialDecoder : Decoder ( MatId, Material )
singleMaterialDecoder =
    D.succeed (,)
        |: D.field "_id" matIdDecoder
        |: D.field "data" materialDecoder


updateMaterialField : MatId -> Field -> Cmd Msg
updateMaterialField (MatId id_) { name_, value_ } =
    case ( value_.edit, value_.prev ) of
        ( UnTouched, _ ) ->
            Cmd.none

        ( ManualInput value, prev ) ->
            updateMaterialFieldImpl id_ name_ prev value

        ( AutoCompleted value, prev ) ->
            updateMaterialFieldImpl id_ name_ prev value


updateMaterialFieldImpl : String -> String -> Maybe String -> String -> Cmd Msg
updateMaterialFieldImpl id_ name_ prev value =
    case Maybe.map ((==) value) prev of
        Just True ->
            Cmd.none

        _ ->
            -- No previous value, or value changed
            H.send ClientRes <|
                put
                    ("/api/materials/" ++ id_ ++ "/" ++ name_)
                    (D.map UpdateMaterialField singleMaterialDecoder)
                    (E.object [ ( "value", E.string value ) ])


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


listMembers : Cmd Msg
listMembers =
    let
        dec =
            D.map ListMembers <|
                D.field "members" <|
                    D.list emailDecoder
    in
        H.send ClientRes <| H.get "/api/members" dec
