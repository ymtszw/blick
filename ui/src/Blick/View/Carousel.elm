module Blick.View.Carousel exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Lazy as Z
import Util
import Blick.Constant exposing (..)
import Blick.Type exposing (..)
import Blick.View.Parts exposing (..)


view : Model -> Html Msg
view { materials, windowSize, carouselPage } =
    let
        cs =
            columnScale windowSize.width
    in
        div [ class "hero is-info" ]
            [ div [ class "hero-body" ]
                [ div [ class "container carousel is-fullhd" ]
                    [ materials
                        |> matDictToList
                        |> Util.split (tilePerRow windowSize.width)
                        |> Util.split rowPerCarouselPage
                        |> List.indexedMap (carouselItem cs carouselPage)
                        |> fillByDummyPage cs
                        |> div [ class "carousel-container" ]
                    , carouselNav (maxCarouselPage windowSize.width (dictSize materials)) carouselPage
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
        [ button (withDisabled (carouselPage <= 0) [ onClick (SetCarouselPage (carouselPage - 1)) ] [ class "pagination-previous" ])
            [ i [ class "fa fa-chevron-left" ] [] ]
        , button (withDisabled (carouselPage >= max - 1) [ onClick (SetCarouselPage (carouselPage + 1)) ] [ class "pagination-next" ])
            [ i [ class "fa fa-chevron-right" ] [] ]
        ]


carouselItem : Int -> Int -> Int -> List (List ( MatId, Material )) -> Html Msg
carouselItem columnScale materialPage pageIndex materialsByPage =
    let
        preloadDelta =
            carouselPreloadDelta columnScale

        contents =
            if materialPage - preloadDelta <= pageIndex && pageIndex <= materialPage + preloadDelta then
                -- Load neighboring pages early; in mobile, preloading range should be narrowed?
                [ Z.lazy2 carouselItemContents columnScale materialsByPage ]
            else
                []
    in
        if materialPage == pageIndex then
            div [ class "carousel-item is-active" ] contents
        else if pageIndex < materialPage then
            div [ class "carousel-item is-overlay is-left-deck" ] contents
        else
            div [ class "carousel-item is-overlay is-right-deck" ] contents


carouselItemContents : Int -> List (List ( MatId, Material )) -> Html Msg
carouselItemContents columnScale materialsByPage =
    materialsByPage
        |> List.map (Z.lazy2 tileRow columnScale)
        |> fillByDummyRow columnScale
        |> div []


tileRow : Int -> List ( MatId, Material ) -> Html Msg
tileRow columnScale materialsPerRow =
    div [ class "columns is-mobile" ] <|
        List.map (Z.lazy2 tileColumn columnScale) materialsPerRow


tileColumn : Int -> ( MatId, Material ) -> Html Msg
tileColumn columnScale ( (MatId id_) as matId, material ) =
    div [ class <| "material column" ++ columnScaleClass columnScale, title material.title ]
        [ a [ href <| "/" ++ id_, onClickNoPropagate (GoTo (Detail matId)) ]
            [ article [ class "card", id id_ ]
                [ div [ class "card-image" ]
                    [ tileThumbnail material.thumbnail_url
                    ]
                , div [ class "card-content" ]
                    [ p [ class "is-size-7 text-nowrap" ] [ text material.title ]
                    ]
                , tags matId material
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


tags : MatId -> Material -> Html Msg
tags ((MatId id_) as matId) { author_email } =
    div [ class "is-overlay tags-on-tile" ]
        [ authorTag (Selector (".card[id='" ++ id_ ++ "']")) matId author_email ]
