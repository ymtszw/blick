module Blick.View.Suggestion exposing (dropdown)

import Html exposing (..)
import Html.Attributes exposing (..)
import Blick.Type exposing (..)
import Blick.View.Parts exposing (onClickNoPropagate)


{-| Take an element as trigger point, attach dropdown to it
-}
dropdown : EditState -> List String -> Html Msg -> Html Msg
dropdown oldEditState items triggerElement =
    div [ class "dropdown is-active" ]
        [ triggerElement
        , menu oldEditState items
        ]


menu : EditState -> List String -> Html Msg
menu oldEditState items =
    case items of
        [] ->
            text ""

        _ ->
            div [ class "dropdown-menu", attribute "role" "menu" ]
                [ div [ class "dropdown-content" ] <| List.map (menuItem oldEditState) items
                ]


menuItem : EditState -> String -> Html Msg
menuItem ({ field } as oldEditState) item =
    a
        [ class "dropdown-item"
        , onClickNoPropagate
            (CompleteEdit oldEditState (Editable field.value_.prev (AutoCompleted item)))
        ]
        [ text item ]
