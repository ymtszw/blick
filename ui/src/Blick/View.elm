module Blick.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Util
import Blick.Type exposing (Model, Msg(..), Id(Id), Material, Url(Url))


view : Model -> Html Msg
view model =
    let
        ( withThumbs, withouts ) =
            List.partition (\( _, { thumbnail_url } ) -> Util.isJust thumbnail_url) model.materials
    in
        section [ class "main" ]
            [ materialTiles withThumbs
            ]


materialTiles : List ( Id, Material ) -> Html Msg
materialTiles materials =
    materials
        |> Util.split 3
        |> List.map tileRow
        |> div [ class "container is-fullhd" ]


tileRow : List ( Id, Material ) -> Html Msg
tileRow materialsUpto3 =
    div [ class "columns" ] <|
        List.map tileColumn materialsUpto3


tileColumn : ( Id, Material ) -> Html Msg
tileColumn ( id, material ) =
    div [ class "column" ]
        [ article [ class "material", key id ]
            [ p [ class "title" ] [ text material.title ]
            , a [ link material.url ] [ thumbnail material.thumbnail_url ]
            ]
        ]


key : Id -> Html.Attribute msg
key (Id id) =
    name id


link : Url -> Html.Attribute msg
link (Url url) =
    href url


thumbnail : Maybe Url -> Html Msg
thumbnail maybeUrl =
    case maybeUrl of
        Just (Url url) ->
            figure [ class "image" ]
                [ img [ src url ] [] ]

        Nothing ->
            figure [ class "image" ]
                []
