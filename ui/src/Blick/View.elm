module Blick.View exposing (view)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Util
import Blick.Type exposing (Model, Msg(..), Route(..), Material)
import Blick.View.Hero as Hero
import Blick.View.Carousel as Carousel
import Blick.View.Table as Table
import Blick.View.Detail as Detail


view : Model -> Html Msg
view { materials, carouselPage, tablePage, matches, filterInput, route } =
    let
        ( withThumbs, withouts ) =
            materials
                |> applyFilter matches
                |> Dict.partition (\_ { thumbnail_url } -> Util.isJust thumbnail_url)
    in
        section [ class "main" ]
            [ modalByRoute materials route
            , Hero.view matches filterInput
            , Carousel.view carouselPage withThumbs
            , Table.view tablePage withouts
            ]


applyFilter : List String -> Dict String Material -> Dict String Material
applyFilter matches materials =
    case matches of
        [] ->
            materials

        _ ->
            Dict.filter (\id _ -> List.member id matches) materials


modalByRoute : Dict String Material -> Route -> Html Msg
modalByRoute materials route =
    case route of
        Detail id ->
            case Dict.get id materials of
                Just material ->
                    Detail.modal material

                Nothing ->
                    text ""

        _ ->
            text ""
