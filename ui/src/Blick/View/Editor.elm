module Blick.View.Editor exposing (modal)

import Json.Decode as D exposing (Decoder)
import Html exposing (..)
import Html.Attributes exposing (..)
import Window
import String.Extra as SE
import Blick.Type exposing (Model, Msg(..), EditState, Field, Email(Email), inputId)
import Blick.Constant exposing (atOrgDomain, maxSuggestions)
import Blick.View.Parts exposing (onClickNoPropagate, onWithoutPropagate, orgLocalNameOrEmail)
import Blick.View.Suggestion as Suggestion


modal : Model -> EditState -> Html Msg
modal { members, windowSize } editState =
    div [ class "modal is-active" ]
        [ div [ class "modal-background", onClickNoPropagate CancelEdit ] []
        , button [ class "modal-close is-large", attribute "aria-label" "close", onClickNoPropagate CancelEdit ] []
        , materialFieldInput members windowSize editState
        ]


materialFieldInput : List Email -> Window.Size -> EditState -> Html Msg
materialFieldInput members windowSize ( id_, field, { left, top, width } ) =
    let
        ( formTop, buttonComesFirst ) =
            formTopAndSwitch windowSize.height top
    in
        Html.form
            [ onWithoutPropagate "submit" (formInputDecoder id_ field.name_)
            , floatingFormStyle (toFloat windowSize.width - left - width) formTop width
            ]
            (formContents buttonComesFirst members id_ field)


floatingFormStyle : Float -> Float -> Float -> Html.Attribute msg
floatingFormStyle right top width =
    style
        [ ( "position", "absolute" )
        , ( "right", toString right ++ "px" )
        , ( "top", toString top ++ "px" )
        , ( "min-width", toString width ++ "px" )
        ]


formTopAndSwitch : Int -> Float -> ( Float, Bool )
formTopAndSwitch height clickedDomTop =
    if clickedDomTop + formHeightWithMargin >= toFloat height then
        ( clickedDomTop - buttonHeightAndGap, True )
    else
        ( clickedDomTop, False )


formContents : Bool -> List Email -> String -> Field -> List (Html Msg)
formContents buttonComesFirst members id_ field =
    if buttonComesFirst then
        [ submitButton, inputByField members id_ field ]
    else
        [ inputByField members id_ field, submitButton ]


buttonHeightAndGap : Float
buttonHeightAndGap =
    39.0


formHeightWithMargin : Float
formHeightWithMargin =
    75.0


formInputDecoder : String -> String -> Decoder Msg
formInputDecoder id_ name_ =
    let
        baseDec =
            D.at [ "target", name_, "value" ] D.string

        sanitizeEmail input =
            if String.contains "@" input then
                input
            else
                input ++ atOrgDomain
    in
        case name_ of
            "author_email" ->
                D.map (\input -> SubmitEdit id_ (Field name_ (sanitizeEmail input))) baseDec

            _ ->
                D.map (\input -> SubmitEdit id_ (Field name_ input)) baseDec


inputByField : List Email -> String -> Field -> Html Msg
inputByField members id_ field =
    case field.name_ of
        "author_email" ->
            if field.value_ == "" || String.endsWith atOrgDomain field.value_ then
                orgEmailInput (List.map (\(Email email) -> SE.leftOfBack atOrgDomain email) members) id_ field
            else
                rawTextInput True id_ field

        _ ->
            rawTextInput True id_ field


orgEmailInput : List String -> String -> Field -> Html Msg
orgEmailInput memberNames id_ field =
    div [ class "field has-addons" ]
        [ span [ class "control has-text-right" ]
            [ Suggestion.dropdown True (List.take maxSuggestions memberNames) <|
                input
                    [ class "input is-small is-rounded has-text-right" -- has-text-right required doubly
                    , type_ "text"
                    , id (inputId id_ field)
                    , name field.name_
                    , placeholder "author.name"
                    , required True
                    , value (orgLocalNameOrEmail (Email field.value_))
                    ]
                    []
            ]
        , span [ class "control" ]
            [ span [ class "button is-small is-static is-rounded has-text-left" ]
                [ text atOrgDomain ]
            ]
        ]


rawTextInput : Bool -> String -> Field -> Html Msg
rawTextInput isRequired id_ field =
    div [ class "field" ]
        [ div [ class "control" ]
            [ input
                [ class "input is-small is-rounded"
                , type_ "text"
                , id (inputId id_ field)
                , name field.name_
                , placeholder field.name_
                , required isRequired
                , value field.value_
                ]
                []
            ]
        ]


submitButton : Html Msg
submitButton =
    div [ class "field" ]
        [ div [ class "control" ]
            [ button
                [ class "button is-link is-small is-rounded"
                , type_ "submit"
                ]
                [ text "Submit" ]
            ]
        ]
