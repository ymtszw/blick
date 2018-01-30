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
            [ hero
            , carousel model.carouselPage withThumbs
            ]


hero : Html Msg
hero =
    div [ class "hero is-primary" ]
        [ div [ class "hero-body" ]
            [ div [ class "container" ]
                [ h1 [ class "title" ] [ text "Blick" ]
                ]
            ]
        ]


carousel : Int -> List ( Id, Material ) -> Html Msg
carousel carouselPage materials =
    div [ class "section" ]
        [ div [ class "container is-fullhd" ]
            [ div [ class "carousel" ]
                [ materials
                    -- 4 per row
                    |> Util.split 4
                    -- 3 per page
                    |> Util.split 3
                    |> List.indexedMap (carouselItem carouselPage)
                    |> div [ class "carousel-container" ]
                , carouselNav carouselPage (List.length materials)
                ]
            ]
        ]


carouselNav : Int -> Int -> Html Msg
carouselNav carouselPage numberOfPages =
    nav [ class "carousel-navigation pagination is-centered", attribute "role" "navigation", attribute "aria-label" "pagination" ]
        [ a (disabled (carouselPage == 0) [ class "pagination-previous" ]) [ i [ class "fa fa-chevron-left" ] [] ]
        , a (disabled (carouselPage == numberOfPages) [ class "pagination-next" ]) [ i [ class "fa fa-chevron-right" ] [] ]
        ]


disabled : Bool -> List (Html.Attribute msg) -> List (Html.Attribute msg)
disabled disabled_ others =
    if disabled_ then
        attribute "disabled" "disabled" :: others
    else
        others


carouselItem : Int -> Int -> List (List ( Id, Material )) -> Html Msg
carouselItem materialPage pageIndex materialsByPage =
    let
        isActive =
            if pageIndex == materialPage then
                style []
            else
                style [ ( "display", "none" ) ]
    in
        materialsByPage
            |> List.map tileRow
            |> div [ class "carousel-item", isActive ]


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
