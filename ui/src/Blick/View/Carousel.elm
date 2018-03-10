module Blick.View.Carousel exposing (view)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Lazy as Z
import Window
import Util
import Blick.Constant exposing (..)
import Blick.Type exposing (Msg(..), Route(..), Selector(S), Material, Url(Url))
import Blick.View.Parts exposing (..)


view : Window.Size -> Int -> Dict String Material -> Html Msg
view { width } carouselPage materials =
    let
        cs =
            columnScale width
    in
        div [ class "hero is-info" ]
            [ div [ class "hero-body" ]
                [ div [ class "container carousel is-fullhd" ]
                    [ materials
                        |> Dict.toList
                        |> Util.split (tilePerRow width)
                        |> Util.split rowPerCarouselPage
                        |> List.indexedMap (carouselItem cs carouselPage)
                        |> fillByDummyPage cs
                        |> div [ class "carousel-container" ]
                    , carouselNav (maxCarouselPage width (Dict.size materials)) carouselPage
                    ]
                ]
            ]


columnScale : Int -> Int
columnScale width =
    bulmaColumnScaleMax // tilePerRow width


fillByDummyPage : Int -> List (Html Msg) -> List (Html Msg)
fillByDummyPage width pages =
    case pages of
        _ :: _ ->
            pages

        _ ->
            fillByDummyRow width []


carouselNav : Int -> Int -> Html Msg
carouselNav max carouselPage =
    nav
        [ class "carousel-navigation pagination is-centered"
        , attribute "role" "navigation"
        , attribute "aria-label" "pagination"
        ]
        [ button (withDisabled (carouselPage <= 0) [ class "pagination-previous", onClick CarouselPrev ])
            [ i [ class "fa fa-chevron-left" ] [] ]
        , button (withDisabled (carouselPage >= max - 1) [ class "pagination-next", onClick CarouselNext ])
            [ i [ class "fa fa-chevron-right" ] [] ]
        ]


carouselItem : Int -> Int -> Int -> List (List ( String, Material )) -> Html Msg
carouselItem columnScale materialPage pageIndex materialsByPage =
    let
        contents =
            if materialPage - 1 <= pageIndex && pageIndex <= materialPage + 1 then
                -- Calculate VDOM already, even if it isn't used for now, ultimately use it via Z.lazy
                Z.lazy2 carouselItemContents columnScale materialsByPage
            else
                -- Not used actually
                text ""
    in
        if materialPage == pageIndex then
            div [ class "carousel-item is-active" ] [ contents ]
        else
            div [ class "carousel-item" ] []


carouselItemContents : Int -> List (List ( String, Material )) -> Html Msg
carouselItemContents columnScale materialsByPage =
    materialsByPage
        |> List.map (Z.lazy2 tileRow columnScale)
        |> fillByDummyRow columnScale
        |> div []


tileRow : Int -> List ( String, Material ) -> Html Msg
tileRow columnScale materialsPerRow =
    div [ class "columns is-mobile" ] <|
        List.map (Z.lazy2 tileColumn columnScale) materialsPerRow


tileColumn : Int -> ( String, Material ) -> Html Msg
tileColumn columnScale ( id_, material ) =
    div [ class <| "material column" ++ columnScaleClass columnScale, title material.title ]
        [ a [ href <| "/" ++ id_, onClickNoPropagate (GoTo (Detail id_)) ]
            [ article [ class "card", id id_ ]
                [ div [ class "card-image" ]
                    [ tileThumbnail material.thumbnail_url
                    ]
                , div [ class "card-content" ]
                    [ p [ class "is-size-7 text-nowrap" ] [ text material.title ]
                    ]
                , tags id_ material
                ]
            ]
        ]


fillByDummyRow : Int -> List (Html Msg) -> List (Html Msg)
fillByDummyRow columnScale rows =
    let
        rowLength =
            List.length rows
    in
        if rowPerCarouselPage > rowLength then
            rows ++ List.repeat (rowPerCarouselPage - rowLength) (dummyRow columnScale)
        else
            rows


dummyRow : Int -> Html Msg
dummyRow columnScale =
    div [ class "columns is-mobile is-invisible" ]
        [ div [ class <| "column" ++ columnScaleClass columnScale ]
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
columnScaleClass : Int -> String
columnScaleClass columnScale =
    " is-" ++ toString columnScale


tileThumbnail : Maybe Url -> Html Msg
tileThumbnail maybeUrl =
    case maybeUrl of
        Just (Url url) ->
            figure [ class "image is-16by9" ]
                [ img [ src url ] [] ]

        Nothing ->
            figure [ class "image is-16by9" ]
                []


tags : String -> Material -> Html Msg
tags id_ { author_email } =
    div [ class "is-overlay tags-on-tile" ]
        [ authorTag (S (".card[id='" ++ id_ ++ "']")) id_ author_email ]
