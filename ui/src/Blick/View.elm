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
        |> Util.split 4
        |> List.map tileRow
        |> div [ class "container is-fullhd" ]


tileRow : List ( Id, Material ) -> Html Msg
tileRow materialsUpto4 =
    div [ class "columns" ] <|
        List.map tileColumn materialsUpto4


tileColumn : ( Id, Material ) -> Html Msg
tileColumn ( id, material ) =
    div [ class "column" ]
        [ a [ link material.url ]
            [ article [ class "material card", key id ]
                [ div [ class "card-image" ]
                    [ thumbnail material.thumbnail_url
                    ]
                , div [ class "card-content" ]
                    [ p [ class "subtitle is-size-5-fullhd is-size-6-widescreen is-size-7-desktop" ] [ text material.title ]
                    ]
                ]
            ]
        ]


key : Id -> Html.Attribute msg
key (Id id_) =
    id id_


link : Url -> Html.Attribute msg
link (Url url) =
    href url


thumbnail : Maybe Url -> Html Msg
thumbnail maybeUrl =
    case maybeUrl of
        Just (Url url) ->
            figure [ class "image is-16by9" ]
                [ img [ src url ] [] ]

        Nothing ->
            figure [ class "image is-16by9" ]
                []
