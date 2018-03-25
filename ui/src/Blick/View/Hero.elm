module Blick.View.Hero exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Blick.Type exposing (Msg(..), Model)


view : Model -> Html Msg
view { filterInput, matches } =
    div [ class "hero is-success" ]
        [ div [ class "hero-body" ]
            [ div [ class "container" ]
                [ div [ class "columns" ]
                    [ div [ class "column is-half is-left" ]
                        [ h1 [ class "title" ] [ text "Blick" ]
                        ]
                    , div [ class "column" ]
                        [ filter matches filterInput ]
                    ]
                ]
            ]
        ]


filter : List id -> String -> Html Msg
filter matches input_ =
    div [ class "field is-expanded" ]
        [ div [ class "control has-icons-left has-icons-right" ]
            [ filterInput matches input_
            , span [ class "icon is-small is-left" ] [ i [ class "fa fa-filter" ] [] ]
            , filterInputResult matches input_
            ]
        ]


filterInput : List id -> String -> Html Msg
filterInput matches input_ =
    input
        [ type_ "text"
        , placeholder "OR filter"
        , onInput Filter
        , class <| "input is-flat" ++ filterInputColor matches input_
        ]
        []


filterInputColor : List id -> String -> String
filterInputColor matches input_ =
    if not (String.isEmpty input_) && List.isEmpty matches then
        " is-danger"
    else
        ""


filterInputResult : List id -> String -> Html Msg
filterInputResult matches input_ =
    case input_ of
        "" ->
            text ""

        _ ->
            span [ class "icon is-small is-right" ] [ text <| toString <| List.length matches ]
