module Blick.View.Hero exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Blick.Type exposing (Msg(..), Id(Id))


view : List Id -> String -> Html Msg
view matches input_ =
    div [ class "hero is-success" ]
        [ div [ class "hero-body" ]
            [ div [ class "container" ]
                [ div [ class "columns" ]
                    [ div [ class "column is-half is-left" ]
                        [ h1 [ class "title" ] [ text "Blick" ]
                        ]
                    , div [ class "column" ]
                        [ filter matches input_ ]
                    ]
                ]
            ]
        ]


filter : List Id -> String -> Html Msg
filter matches input_ =
    div [ class "field is-expanded" ]
        [ div [ class "control has-icons-left has-icons-right" ]
            [ input [ type_ "text", placeholder "OR filter", class <| "input is-flat" ++ filterInputColor matches input_, onInput Filter ] []
            , span [ class "icon is-small is-left" ] [ i [ class "fa fa-filter" ] [] ]
            , filterInputResult matches input_
            ]
        ]


filterInputColor : List Id -> String -> String
filterInputColor matches input_ =
    if not (String.isEmpty input_) && List.isEmpty matches then
        " is-danger"
    else
        ""


filterInputResult : List Id -> String -> Html Msg
filterInputResult matches input_ =
    case input_ of
        "" ->
            text ""

        _ ->
            span [ class "icon is-small is-right" ] [ text <| toString <| List.length matches ]
