module Blick.View.Suggestion exposing (dropdown)

import Html exposing (..)
import Html.Attributes exposing (..)
import Keyboard.Event exposing (KeyboardEvent)
import Keyboard.Key exposing (Key(..))
import Blick.Type exposing (..)
import Blick.View.Parts exposing (onClickNoPropagate, onWithoutPropagate)
import Blick.Keybinds exposing (decodeKeyboardEventSelectively)


{-| Take an element as trigger point, attach dropdown to it
-}
dropdown : Maybe Int -> EditState -> List String -> (Html.Attribute Msg -> Html Msg) -> Html Msg
dropdown selectedSuggestion oldEditState suggestions makeTriggerElement =
    div [ class "dropdown is-active" ]
        [ makeTriggerElement (keydownHandler oldEditState selectedSuggestion suggestions)
        , menu oldEditState selectedSuggestion suggestions
        ]


keydownHandler : EditState -> Maybe Int -> List String -> Html.Attribute Msg
keydownHandler oldEditState selectedSuggestion suggestions =
    case suggestions of
        [] ->
            -- Practically means `Attribute.none`, not handling at all
            style []

        _ ->
            let
                numOfSuggestions =
                    List.length suggestions
            in
                case selectedSuggestion of
                    Just index ->
                        onWithoutPropagate "keydown" <|
                            decodeKeyboardEventSelectively ([ Enter ] :: upAndDownKeys) <|
                                \event ->
                                    if event.keyCode == Enter then
                                        complete oldEditState suggestions index
                                    else
                                        selectSuggestionOrNothing numOfSuggestions selectedSuggestion event

                    Nothing ->
                        onWithoutPropagate "keydown" <|
                            decodeKeyboardEventSelectively upAndDownKeys <|
                                selectSuggestionOrNothing numOfSuggestions selectedSuggestion


upAndDownKeys : List (List Key)
upAndDownKeys =
    [ [ Up ], [ Ctrl Nothing, P ], [ Down ], [ Ctrl Nothing, N ] ]


complete : EditState -> List String -> Int -> Maybe Msg
complete ({ field } as oldEditState) suggestions index =
    case List.drop index suggestions of
        [] ->
            -- Should not happen
            Nothing

        s :: _ ->
            Just (CompleteEdit oldEditState (Editable field.value_.prev (AutoCompleted s)))


selectSuggestionOrNothing : Int -> Maybe Int -> KeyboardEvent -> Maybe Msg
selectSuggestionOrNothing numOfSuggestions selectedSuggestion { ctrlKey, keyCode } =
    if keyCode == Down || (ctrlKey && keyCode == N) then
        Just (SelectSuggestion (cycleSelectedSuggestion (\v -> v + 1) numOfSuggestions selectedSuggestion))
    else if keyCode == Up || (ctrlKey && keyCode == P) then
        Just (SelectSuggestion (cycleSelectedSuggestion (\v -> v - 1) numOfSuggestions selectedSuggestion))
    else
        Nothing


cycleSelectedSuggestion : (Int -> Int) -> Int -> Maybe Int -> Int
cycleSelectedSuggestion plusOrMinus1 numOfSuggestions selectedSuggestion =
    let
        calculateNew from =
            let
                tmpNew =
                    plusOrMinus1 from
            in
                if tmpNew >= numOfSuggestions then
                    -- Upper overflow
                    0
                else if tmpNew < 0 then
                    -- Lower overflow
                    numOfSuggestions - 1
                else
                    tmpNew
    in
        case selectedSuggestion of
            Just v ->
                calculateNew v

            Nothing ->
                calculateNew -1


menu : EditState -> Maybe Int -> List String -> Html Msg
menu oldEditState selectedSuggestion suggestions =
    case suggestions of
        [] ->
            text ""

        _ ->
            div [ class "dropdown-menu", attribute "role" "menu" ]
                [ div [ class "dropdown-content" ] <| List.indexedMap (menuItem oldEditState selectedSuggestion) suggestions
                ]


menuItem : EditState -> Maybe Int -> Int -> String -> Html Msg
menuItem ({ field } as oldEditState) selectedSuggestion index item =
    a
        [ class <| "dropdown-item" ++ selectedClass selectedSuggestion index
        , onClickNoPropagate
            (CompleteEdit oldEditState (Editable field.value_.prev (AutoCompleted item)))
        ]
        [ text item ]


selectedClass : Maybe Int -> Int -> String
selectedClass selectedSuggestion index =
    case Maybe.map ((==) index) selectedSuggestion of
        Just True ->
            " is-active"

        _ ->
            ""
