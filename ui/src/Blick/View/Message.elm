module Blick.View.Message exposing (view)

import Date
import Dict exposing (Dict)
import Time exposing (Time)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Blick.Type exposing (..)
import Blick.Constant exposing (exceptionCloseDelay, exceptionCloseDuration)


view : Dict Time Exception -> Html Msg
view exceptions =
    div [ class "exceptions" ]
        [ div [ class "columns" ]
            [ closeTransitionStyleElement
            , exceptions
                |> Dict.toList
                |> List.map notification
                |> div [ class "column is-offset-half is-half" ]
            ]
        ]


closeTransitionStyleElement : Html msg
closeTransitionStyleElement =
    node "style"
        [ type_ "text/css" ]
        [ text <|
            ".exceptions .message.is-closed{transition:all ease-out "
                ++ toString exceptionCloseDuration
                ++ "ms "
                ++ toString exceptionCloseDelay
                ++ "ms}"
        ]


notification : ( Time, Exception ) -> Html Msg
notification ( time_, { message, description, details, isOpen } ) =
    div
        [ class <| "message is-danger" ++ isOpenClass isOpen
        , id <| "exception-" ++ toString time_
        ]
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


isOpenClass : Bool -> String
isOpenClass isOpen =
    if isOpen then
        ""
    else
        " is-closed"


detailList : List String -> Html Msg
detailList details =
    case details of
        [] ->
            text ""

        _ ->
            details
                |> List.map (\str -> li [ class "pre" ] [ text str ])
                |> ul [ class "is-size-7 details" ]
