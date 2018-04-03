module Blick.Keybinds exposing (decodeKeyboardEventSelectively, subscriptions)

import Json.Decode exposing (Decoder)
import Keyboard exposing (KeyCode)
import Keyboard.Event exposing (KeyboardEvent, considerKeyboardEvent)
import Keyboard.Key exposing (Key(..))
import Util
import Blick.Type exposing (..)


-- Key-aware event decoders


decodeKeyboardEventSelectively : List (List Key) -> (KeyboardEvent -> Maybe Msg) -> Decoder Msg
decodeKeyboardEventSelectively targetKeyBinds maybeMsg =
    considerKeyboardEvent <|
        \event ->
            if matchTargetKeybinds event targetKeyBinds then
                maybeMsg event
            else
                -- Non-target key inputs are delegated to browser default
                Nothing


matchTargetKeybinds : KeyboardEvent -> List (List Key) -> Bool
matchTargetKeybinds event targetKeyBinds =
    case targetKeyBinds of
        [] ->
            False

        keyBind :: kbs ->
            isTargetedKeybindEvent event keyBind || matchTargetKeybinds event kbs


isTargetedKeybindEvent : KeyboardEvent -> List Key -> Bool
isTargetedKeybindEvent { altKey, ctrlKey, shiftKey, metaKey, keyCode } keys =
    List.all
        (\key ->
            case key of
                Shift _ ->
                    shiftKey

                Ctrl _ ->
                    ctrlKey

                Alt ->
                    altKey

                Command ->
                    metaKey

                other ->
                    other == keyCode
        )
        keys


subscriptions : Model -> Sub Msg
subscriptions model =
    Keyboard.downs (globalKeydownHandler model)


globalKeydownHandler : Model -> KeyCode -> Msg
globalKeydownHandler { editing, filter } keyCode =
    if keyCode == 27 && Util.isJust editing then
        -- Escape from editor
        CancelEdit
    else if keyCode == 27 && filter.focused then
        -- Escape from filterBox
        FocusFilter False
    else if (keyCode == 191 || keyCode == 83) && not filter.focused then
        -- '/' or 'S' in JIS keyboard without filterBox focus
        FocusFilter True
    else
        NoOp
