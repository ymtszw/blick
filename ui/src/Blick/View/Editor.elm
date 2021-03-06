module Blick.View.Editor exposing (modal)

import Json.Decode as D
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import String.Extra as SE
import Blick.Type exposing (..)
import Blick.Constant exposing (atOrgDomain, maxSuggestions)
import Blick.View.Parts exposing (onClickNoPropagate, onWithoutPropagate, orgLocalNameOrEmail)
import Blick.View.Suggestion as Suggestion


modal : Model -> EditState -> Html Msg
modal model editState =
    div [ class "modal is-active" ]
        [ div [ class "modal-background", onClickNoPropagate CancelEdit ] []
        , button [ class "modal-close is-large", attribute "aria-label" "close", onClickNoPropagate CancelEdit ] []
        , materialFieldInput model editState
        ]


materialFieldInput : Model -> EditState -> Html Msg
materialFieldInput ({ windowSize } as model) ({ matId, field, domRect } as editState) =
    let
        ( formTop, buttonComesFirst ) =
            formTopAndSwitch windowSize.height domRect.top
    in
        Html.form
            [ onWithoutPropagate "submit" (D.succeed (SubmitEdit matId (finalizeEdit field)))
            , floatingFormStyle (toFloat windowSize.width - domRect.left - domRect.width) formTop domRect.width
            ]
            (formContents buttonComesFirst model editState)


floatingFormStyle : Float -> Float -> Float -> Html.Attribute msg
floatingFormStyle right top width =
    style
        [ ( "position", "absolute" )
        , ( "right", toString right ++ "px" )
        , ( "top", toString top ++ "px" )
        , ( "min-width", toString width ++ "px" )
        ]


finalizeEdit : Field -> Field
finalizeEdit ({ name_, value_ } as field) =
    case name_ of
        "author_email" ->
            case value_.edit of
                ManualInput value ->
                    { field | value_ = { value_ | edit = ManualInput (sanitizeEmail value) } }

                AutoCompleted value ->
                    { field | value_ = { value_ | edit = AutoCompleted (sanitizeEmail value) } }

                UnTouched ->
                    field

        _ ->
            field


sanitizeEmail : String -> String
sanitizeEmail input =
    if String.contains "@" input then
        input
    else
        input ++ atOrgDomain


formTopAndSwitch : Int -> Float -> ( Float, Bool )
formTopAndSwitch height clickedDomTop =
    if clickedDomTop + formHeightWithMargin >= toFloat height then
        ( clickedDomTop - buttonHeightAndGap, True )
    else
        ( clickedDomTop, False )


formContents : Bool -> Model -> EditState -> List (Html Msg)
formContents buttonComesFirst model editState =
    if buttonComesFirst then
        [ submitButton, inputByField model editState ]
    else
        [ inputByField model editState, submitButton ]


buttonHeightAndGap : Float
buttonHeightAndGap =
    39.0


formHeightWithMargin : Float
formHeightWithMargin =
    75.0


inputByField : Model -> EditState -> Html Msg
inputByField { selectedSuggestion, members } ({ field } as editState) =
    case field.name_ of
        "author_email" ->
            let
                filteredMembers =
                    filterMembers field.value_ members
            in
                case Maybe.map (String.endsWith atOrgDomain) field.value_.prev of
                    Just False ->
                        rawTextInput True
                            (Just (List.map (\(Email email) -> email) filteredMembers))
                            selectedSuggestion
                            editState

                    _ ->
                        orgEmailInput
                            (List.map (\(Email email) -> SE.leftOfBack atOrgDomain email) filteredMembers)
                            selectedSuggestion
                            editState

        _ ->
            rawTextInput True Nothing selectedSuggestion editState


filterMembers : Editable -> List Email -> List Email
filterMembers { edit } members =
    case edit of
        UnTouched ->
            []

        AutoCompleted _ ->
            []

        ManualInput "" ->
            []

        ManualInput v ->
            let
                lv =
                    String.toLower v
            in
                List.filter
                    (\(Email email) ->
                        let
                            le =
                                String.toLower email
                        in
                            String.startsWith lv le || String.startsWith lv (SE.rightOf "." le)
                    )
                    members


orgEmailInput : List String -> Maybe Int -> EditState -> Html Msg
orgEmailInput memberNames selectedSuggestion ({ matId, field } as editState) =
    div [ class "field has-addons" ]
        [ span [ class "control has-text-right" ]
            [ Suggestion.dropdown selectedSuggestion editState (List.take maxSuggestions memberNames) <|
                \keydownHandler ->
                    input
                        [ class "input is-small is-rounded has-text-right" -- has-text-right required doubly
                        , type_ "text"
                        , id (inputId matId field)
                        , name field.name_
                        , placeholder "author.name"
                        , autocomplete False
                        , required True
                        , valueOrDefaultValue (orgLocalNameOrEmail << Email << Maybe.withDefault "") field.value_
                        , keydownHandler
                        , onInput (InputEdit editState << Editable field.value_.prev << ManualInput)
                        ]
                        []
            ]
        , span [ class "control" ]
            [ span [ class "button is-small is-static is-rounded has-text-left" ]
                [ text atOrgDomain ]
            ]
        ]


valueOrDefaultValue : (Maybe String -> String) -> Editable -> Html.Attribute Msg
valueOrDefaultValue transformPrev { prev, edit } =
    case edit of
        UnTouched ->
            defaultValue (transformPrev prev)

        AutoCompleted val ->
            value val

        ManualInput val ->
            value val


rawTextInput : Bool -> Maybe (List String) -> Maybe Int -> EditState -> Html Msg
rawTextInput isRequired maybeSuggestions selectedSuggestion ({ matId, field } as editState) =
    let
        textInput keydownHandler =
            input
                [ class "input is-small is-rounded"
                , type_ "text"
                , id (inputId matId field)
                , name field.name_
                , placeholder field.name_
                , autocomplete False
                , required isRequired
                , valueOrDefaultValue (Maybe.withDefault "") field.value_
                , keydownHandler
                , onInput (InputEdit editState << Editable field.value_.prev << ManualInput)
                ]
                []
    in
        div [ class "field" ]
            [ div [ class "control" ]
                [ maybeSuggestions
                    |> Maybe.map (\suggestions -> Suggestion.dropdown selectedSuggestion editState (List.take maxSuggestions suggestions) textInput)
                    |> Maybe.withDefault (textInput (style []))
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
