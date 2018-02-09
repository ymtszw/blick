module Blick.View.Message exposing (view)

import Date
import Dict exposing (Dict)
import Time exposing (Time)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Blick.Type exposing (..)


view : Dict Time Exception -> Html Msg
view exceptions =
    div [ class "exception" ]
        [ div [ class "columns" ]
            [ exceptions
                |> Dict.toList
                |> List.map notification
                |> div [ class "column is-offset-half is-half" ]
            ]
        ]


notification : ( Time, Exception ) -> Html Msg
notification ( time_, { message, description, details } ) =
    div [ class "message is-danger", id <| toString time_ ]
        [ div [ class "message-header" ]
            [ p [] [ text message ]
            , small [ class "is-size-7" ] [ text <| toString <| Date.fromTime time_ ]
            , button [ class "delete", onClick (CloseErr time_) ] []
            ]
        , div [ class "message-body content is-small" ]
            [ p [] [ text description ]
            , detailList details
            ]
        ]


detailList : List String -> Html Msg
detailList details =
    case details of
        [] ->
            text ""

        _ ->
            details
                |> List.map (\str -> li [ class "pre" ] [ text str ])
                |> ul [ class "is-size-7 details" ]
