module Blick.View.Hero exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onFocus, onBlur)
import Blick.Type exposing (Msg(..), Model, FilterState)
import Blick.Constant exposing (filterBoxId)


view : Model -> Html Msg
view { filter, matches } =
    div [ class "hero is-success" ]
        [ div [ class "hero-body" ]
            [ div [ class "container" ]
                [ div [ class "columns" ]
                    [ div [ class "column is-half is-left" ]
                        [ h1 [ class "title" ] [ text "Blick" ]
                        ]
                    , div [ class "column" ]
                        [ filterBox matches filter ]
                    ]
                ]
            ]
        ]


filterBox : List id -> FilterState -> Html Msg
filterBox matches { value_ } =
    div [ class "field is-expanded" ]
        [ div [ class "control has-icons-left has-icons-right" ]
            [ filterInput matches value_
            , span [ class "icon is-small is-left" ] [ i [ class "fa fa-filter" ] [] ]
            , filterInputResult matches value_
            ]
        ]


filterInput : List id -> String -> Html Msg
filterInput matches value_ =
    input
        [ type_ "text"
        , placeholder "OR filter"
        , onInput InputFilter
        , onFocus (SetFilterFocus True)
        , onBlur (SetFilterFocus False)
        , class <| "input is-flat" ++ filterInputColor matches value_
        , id filterBoxId
        ]
        []


filterInputColor : List id -> String -> String
filterInputColor matches value_ =
    if not (String.isEmpty value_) && List.isEmpty matches then
        " is-danger"
    else
        ""


filterInputResult : List id -> String -> Html Msg
filterInputResult matches value_ =
    case value_ of
        "" ->
            text ""

        _ ->
            span [ class "icon is-small is-right" ] [ text <| toString <| List.length matches ]
