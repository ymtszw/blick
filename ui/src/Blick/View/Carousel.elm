module Blick.View.Carousel exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Lazy as Z
import Util
import Blick.Constant exposing (..)
import Blick.Type exposing (Msg(..), Id(Id), Material, Url(Url))
import Blick.View.Parts exposing (..)


view : Int -> List ( Id, Material ) -> Html Msg
view carouselPage materials =
    div [ class "hero is-info" ]
        [ div [ class "hero-body" ]
            [ div [ class "container carousel is-fullhd" ]
                [ materials
                    |> Util.split tilePerRow
                    |> Util.split rowPerPage
                    |> List.indexedMap (carouselItem carouselPage)
                    |> fillByDummyPage
                    |> div [ class "carousel-container" ]
                , carouselNav carouselPage (List.length materials)
                ]
            ]
        ]


fillByDummyPage : List (Html Msg) -> List (Html Msg)
fillByDummyPage pages =
    case pages of
        _ :: _ ->
            pages

        _ ->
            fillByDummyRow []


carouselNav : Int -> Int -> Html Msg
carouselNav carouselPage numberOfPages =
    nav
        [ class "carousel-navigation pagination is-centered"
        , attribute "role" "navigation"
        , attribute "aria-label" "pagination"
        ]
        [ button (disabled (carouselPage <= 0) [ class "pagination-previous", onClick CarouselPrev ])
            [ i [ class "fa fa-chevron-left" ] [] ]
        , button (disabled (carouselPage >= maxCarouselPage numberOfPages) [ class "pagination-next", onClick CarouselNext ])
            [ i [ class "fa fa-chevron-right" ] [] ]
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
            |> fillByDummyRow
            |> div [ class "carousel-item", isActive ]


tileRow : List ( Id, Material ) -> Html Msg
tileRow materialsUpto4 =
    div [ class "columns" ] <|
        List.map (Z.lazy tileColumn) materialsUpto4


tileColumn : ( Id, Material ) -> Html Msg
tileColumn ( Id id_, material ) =
    div [ class <| "column" ++ columnSizeClass, title material.title ]
        [ a [ href <| "/" ++ id_ ]
            [ article [ class "material card", id id_ ]
                [ div [ class "card-image" ]
                    [ tileThumbnail material.thumbnail_url
                    ]
                , div [ class "card-content" ]
                    [ p [ class "is-size-7 text-nowrap" ] [ text material.title ]
                    ]
                , tags material
                ]
            ]
        ]


fillByDummyRow : List (Html Msg) -> List (Html Msg)
fillByDummyRow rows =
    case rows of
        [] ->
            [ dummyRow, dummyRow, dummyRow ]

        [ _ ] ->
            rows ++ [ dummyRow, dummyRow ]

        [ _, _ ] ->
            rows ++ [ dummyRow ]

        _ ->
            rows


dummyRow : Html Msg
dummyRow =
    div [ class "columns is-invisible" ]
        [ div [ class <| "column" ++ columnSizeClass ]
            [ article [ class "material card" ]
                [ div [ class "card-image" ] [ tileThumbnail Nothing ]
                , div [ class "card-content" ]
                    [ p [ class "is-size-7 text-nowrap" ] [ text "Dummy" ]
                    ]
                ]
            ]
        ]


{-| Must fix size, otherwise it grows when there aren't enough columns
-}
columnSizeClass : String
columnSizeClass =
    " is-" ++ toString (bulmaColumnScaleMax // tilePerRow)


tileThumbnail : Maybe Url -> Html Msg
tileThumbnail maybeUrl =
    case maybeUrl of
        Just (Url url) ->
            figure [ class "image is-16by9" ]
                [ img [ src url ] [] ]

        Nothing ->
            figure [ class "image is-16by9" ]
                []


tags : Material -> Html Msg
tags { author_email } =
    div [ class "is-overlay tags-on-tile" ]
        [ Z.lazy authorTag author_email ]
