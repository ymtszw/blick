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
import Blick.View.Message as Message
import Blick.View.Editor as Editor


view : Model -> Html Msg
view model =
    let
        ( withThumbs, withouts ) =
            model.materials
                |> applyFilter model.matches
                |> Dict.partition (\_ { thumbnail_url } -> Util.isJust thumbnail_url)
    in
        section [ class "main" ]
            [ modals model
            , Hero.view model
            , Message.view model.exceptions
            , Carousel.view { model | materials = withThumbs }
            , Table.view { model | materials = withouts }
            ]


applyFilter : List String -> Dict String Material -> Dict String Material
applyFilter matches materials =
    case matches of
        [] ->
            materials

        _ ->
            Dict.filter (\id_ _ -> List.member id_ matches) materials


modals : Model -> Html Msg
modals model =
    withEditor model <|
        case model.route of
            Detail id_ ->
                case Dict.get id_ model.materials of
                    Just material ->
                        [ Detail.modal model.windowSize id_ material ]

                    Nothing ->
                        []

            _ ->
                []


withEditor : Model -> List (Html Msg) -> Html Msg
withEditor model others =
    div [ id "modals" ] <|
        case model.editing of
            Just editState ->
                others ++ [ Editor.modal model editState ]

            Nothing ->
                others
