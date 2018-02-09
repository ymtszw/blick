module Blick.View.Carousel exposing (view)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Lazy as Z
import Util
import Blick.Constant exposing (..)
import Blick.Type exposing (Msg(..), Route(..), Material, Url(Url))
import Blick.View.Parts exposing (..)


view : Int -> Dict String Material -> Html Msg
view carouselPage materials =
    div [ class "hero is-info" ]
        [ div [ class "hero-body" ]
            [ div [ class "container carousel is-fullhd" ]
                [ materials
                    |> Dict.toList
                    |> Util.split tilePerRow
                    |> Util.split rowPerCarouselPage
                    |> List.indexedMap (Z.lazy3 carouselItem carouselPage)
                    |> fillByDummyPage
                    |> div [ class "carousel-container" ]
                , carouselNav carouselPage (Dict.size materials)
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
carouselNav carouselPage numberOfMaterials =
    nav
        [ class "carousel-navigation pagination is-centered"
        , attribute "role" "navigation"
        , attribute "aria-label" "pagination"
        ]
        [ button (withDisabled (carouselPage <= 0) [ class "pagination-previous", onClick CarouselPrev ])
            [ i [ class "fa fa-chevron-left" ] [] ]
        , button (withDisabled (carouselPage >= maxCarouselPage numberOfMaterials) [ class "pagination-next", onClick CarouselNext ])
            [ i [ class "fa fa-chevron-right" ] [] ]
        ]


carouselItem : Int -> Int -> List (List ( String, Material )) -> Html Msg
carouselItem materialPage pageIndex materialsByPage =
    let
        contents =
            if materialPage - 1 <= pageIndex && pageIndex <= materialPage + 1 then
                -- Calculate VDOM already, even if it isn't used for now, ultimately use it via Z.lazy
                Z.lazy carouselItemContents materialsByPage
            else
                -- Not used actually
                text ""
    in
        if materialPage == pageIndex then
            div [ class "carousel-item is-active" ] [ contents ]
        else
            div [ class "carousel-item" ] []


carouselItemContents : List (List ( String, Material )) -> Html Msg
carouselItemContents materialsByPage =
    materialsByPage
        |> List.map (Z.lazy tileRow)
        |> fillByDummyRow
        |> div []


tileRow : List ( String, Material ) -> Html Msg
tileRow materialsUpto4 =
    div [ class "columns" ] <|
        List.map (Z.lazy tileColumn) materialsUpto4


tileColumn : ( String, Material ) -> Html Msg
tileColumn ( id_, material ) =
    div [ class <| "material column" ++ columnSizeClass, title material.title ]
        [ a [ href <| "/" ++ id_, onClickNoPropagate (GoTo (Detail id_)) ]
            [ article [ class "card", id id_ ]
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
    let
        rowLength =
            List.length rows
    in
        if rowPerCarouselPage > rowLength then
            rows ++ List.repeat (rowPerCarouselPage - rowLength) dummyRow
        else
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
