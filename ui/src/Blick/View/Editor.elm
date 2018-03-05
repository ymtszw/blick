module Blick.View.Editor exposing (modal)

import Json.Decode as D exposing (Decoder)
import Html exposing (..)
import Html.Attributes exposing (..)
import Window
import Blick.Type exposing (Msg(..), Field, ClickPos, inputId)
import Blick.View.Parts exposing (..)


modal : Window.Size -> ( String, Field, ClickPos ) -> Html Msg
modal _ ( id_, field, _ ) =
    div [ class "modal is-active" ]
        [ div [ class "modal-background", onClickNoPropagate (\_ -> CancelEdit) ] []
        , button [ class "modal-close is-large", attribute "aria-label" "close", onClickNoPropagate (\_ -> CancelEdit) ] []
        , materialFieldInput id_ field
        ]


materialFieldInput : String -> Field -> Html Msg
materialFieldInput id_ field =
    Html.form [ onSubmitNoPropagate (formInputDecoder id_ field.name_) ]
        [ inputByField id_ field
        , div [ class "field" ]
            [ div [ class "control" ]
                [ button
                    [ class "button is-link is-small is-rounded"
                    , type_ "submit"
                    ]
                    [ text "Submit" ]
                ]
            ]
        ]


formInputDecoder : String -> String -> Decoder Msg
formInputDecoder id_ name_ =
    let
        baseDec =
            D.at [ "target", name_, "value" ] D.string

        sanitizeEmail input =
            if String.contains "@" input then
                input
            else
                input ++ "@access-company.com"
    in
        case name_ of
            "author_email" ->
                baseDec
                    |> D.map sanitizeEmail
                    |> D.map (\email -> SubmitEdit id_ (Field "author_email" email))

            _ ->
                D.map (\input -> SubmitEdit id_ (Field name_ input)) baseDec


inputByField : String -> Field -> Html Msg
inputByField id_ field =
    case field.name_ of
        "author_email" ->
            if field.value_ == "" || String.endsWith "@access-company.com" field.value_ then
                orgEmailInput id_ field
            else
                rawTextInput id_ field

        _ ->
            rawTextInput id_ field


orgEmailInput : String -> Field -> Html Msg
orgEmailInput id_ field =
    div [ class "field has-addons" ]
        [ span [ class "control" ]
            [ input
                [ class "input is-small is-rounded has-text-right"
                , type_ "text"
                , id (inputId id_ field)
                , name field.name_
                , placeholder "author.name"
                , value (orgLocalNameOrEmail field.value_)
                ]
                []
            ]
        , span [ class "control" ]
            [ span [ class "button is-small is-static is-rounded has-text-left" ]
                [ text "@access-company.com" ]
            ]
        ]


rawTextInput : String -> Field -> Html Msg
rawTextInput id_ field =
    div [ class "field" ]
        [ div [ class "control" ]
            [ input
                [ class "input is-small is-rounded"
                , type_ "text"
                , id (inputId id_ field)
                , name field.name_
                , placeholder field.name_
                , value field.value_
                ]
                []
            ]
        ]
