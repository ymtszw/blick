module Blick.View.Editor exposing (modal)

import Json.Decode as D exposing (Decoder)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Window
import String.Extra as SE
import Blick.Type exposing (..)
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
materialFieldInput members windowSize ( matId, field, { left, top, width } ) =
    let
        ( formTop, buttonComesFirst ) =
            formTopAndSwitch windowSize.height top
    in
        Html.form
            [ onWithoutPropagate "submit" (formInputDecoder matId field)
            , floatingFormStyle (toFloat windowSize.width - left - width) formTop width
            ]
            (formContents buttonComesFirst members matId field)


floatingFormStyle : Float -> Float -> Float -> Html.Attribute msg
floatingFormStyle right top width =
    style
        [ ( "position", "absolute" )
        , ( "right", toString right ++ "px" )
        , ( "top", toString top ++ "px" )
        , ( "min-width", toString width ++ "px" )
        ]


formInputDecoder : MatId -> Field -> Decoder Msg
formInputDecoder matId ({ name_, value_ } as field) =
    let
        baseDec =
            D.at [ "target", name_, "value" ] D.string
    in
        case name_ of
            "author_email" ->
                D.map
                    (\input ->
                        SubmitEdit matId
                            { field | value_ = { value_ | edit = sanitizeEmail input } }
                    )
                    baseDec

            _ ->
                D.map
                    (\input ->
                        SubmitEdit matId
                            { field | value_ = { value_ | edit = Just input } }
                    )
                    baseDec


sanitizeEmail : String -> Maybe String
sanitizeEmail input =
    if input == "" then
        Nothing
    else if String.contains "@" input then
        Just input
    else
        Just (input ++ atOrgDomain)


formTopAndSwitch : Int -> Float -> ( Float, Bool )
formTopAndSwitch height clickedDomTop =
    if clickedDomTop + formHeightWithMargin >= toFloat height then
        ( clickedDomTop - buttonHeightAndGap, True )
    else
        ( clickedDomTop, False )


formContents : Bool -> List Email -> MatId -> Field -> List (Html Msg)
formContents buttonComesFirst members matId field =
    if buttonComesFirst then
        [ submitButton, inputByField members matId field ]
    else
        [ inputByField members matId field, submitButton ]


buttonHeightAndGap : Float
buttonHeightAndGap =
    39.0


formHeightWithMargin : Float
formHeightWithMargin =
    75.0


inputByField : List Email -> MatId -> Field -> Html Msg
inputByField members matId ({ name_, value_ } as field) =
    case name_ of
        "author_email" ->
            let
                filteredMembers =
                    filterMembers value_ members
            in
                case Maybe.map (String.endsWith atOrgDomain) value_.prev of
                    Just False ->
                        rawTextInput True matId field

                    _ ->
                        orgEmailInput
                            (List.map (\(Email email) -> SE.leftOfBack atOrgDomain email) filteredMembers)
                            matId
                            field

        _ ->
            rawTextInput True matId field


filterMembers : ValueState -> List Email -> List Email
filterMembers { edit } members =
    case edit of
        Nothing ->
            []

        Just "" ->
            []

        Just v ->
            List.filter
                (\(Email email) -> String.startsWith v email || String.startsWith v (SE.rightOf "." email))
                members


orgEmailInput : List String -> MatId -> Field -> Html Msg
orgEmailInput memberNames matId ({ name_, value_ } as field) =
    div [ class "field has-addons" ]
        [ span [ class "control has-text-right" ]
            [ Suggestion.dropdown True (List.take maxSuggestions memberNames) <|
                input
                    [ class "input is-small is-rounded has-text-right" -- has-text-right required doubly
                    , type_ "text"
                    , id (inputId matId field)
                    , name name_
                    , placeholder "author.name"
                    , autocomplete False
                    , required True
                    , defaultValue (orgLocalNameOrEmail (Email (Maybe.withDefault "" value_.prev)))
                    , onInput InputEdit
                    ]
                    []
            ]
        , span [ class "control" ]
            [ span [ class "button is-small is-static is-rounded has-text-left" ]
                [ text atOrgDomain ]
            ]
        ]


rawTextInput : Bool -> MatId -> Field -> Html Msg
rawTextInput isRequired matId ({ name_, value_ } as field) =
    div [ class "field" ]
        [ div [ class "control" ]
            [ input
                [ class "input is-small is-rounded"
                , type_ "text"
                , id (inputId matId field)
                , name name_
                , placeholder name_
                , required isRequired
                , defaultValue (Maybe.withDefault "" value_.prev)
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
