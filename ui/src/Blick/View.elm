module Blick.View exposing (view)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Window
import Util
import Blick.Type exposing (Model, Msg(..), Field, DOMRect, Route(..), Material)
import Blick.View.Hero as Hero
import Blick.View.Carousel as Carousel
import Blick.View.Table as Table
import Blick.View.Detail as Detail
import Blick.View.Message as Message
import Blick.View.Editor as Editor


view : Model -> Html Msg
view { materials, editing, carouselPage, tablePage, matches, filterInput, route, exceptions, windowSize } =
    let
        ( withThumbs, withouts ) =
            materials
                |> applyFilter matches
                |> Dict.partition (\_ { thumbnail_url } -> Util.isJust thumbnail_url)
    in
        section [ class "main" ]
            [ modals materials windowSize editing route
            , Hero.view matches filterInput
            , Message.view exceptions
            , Carousel.view windowSize carouselPage withThumbs
            , Table.view windowSize tablePage withouts
            ]


applyFilter : List String -> Dict String Material -> Dict String Material
applyFilter matches materials =
    case matches of
        [] ->
            materials

        _ ->
            Dict.filter (\id_ _ -> List.member id_ matches) materials


modals : Dict String Material -> Window.Size -> Maybe ( String, Field, DOMRect ) -> Route -> Html Msg
modals materials windowSize editing route =
    withEditor windowSize editing <|
        case route of
            Detail id_ ->
                case Dict.get id_ materials of
                    Just material ->
                        [ Detail.modal windowSize id_ material ]

                    Nothing ->
                        []

            _ ->
                []


withEditor : Window.Size -> Maybe ( String, Field, DOMRect ) -> List (Html Msg) -> Html Msg
withEditor windowSize editing others =
    div [ id "modals" ] <|
        case editing of
            Just editState ->
                others ++ [ Editor.modal windowSize editState ]

            Nothing ->
                others
