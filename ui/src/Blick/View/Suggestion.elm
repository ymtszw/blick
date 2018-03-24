module Blick.View.Suggestion exposing (dropdown)

import Html exposing (..)
import Html.Attributes exposing (..)
import Blick.Type exposing (..)


{-| Take an element as trigger point, attach dropdown to it
-}
dropdown : Bool -> List String -> Html Msg -> Html Msg
dropdown isActive items triggerElement =
    div [ class <| "dropdown" ++ isActiveClass isActive ]
        [ triggerElement
        , if isActive then
            menu items
          else
            text ""
        ]


isActiveClass : Bool -> String
isActiveClass isActive =
    if isActive then
        " is-active"
    else
        ""


menu : List String -> Html Msg
menu items =
    case items of
        [] ->
            text ""

        _ ->
            div [ class "dropdown-menu", attribute "role" "menu" ]
                [ div [ class "dropdown-content" ] <|
                    List.map (\item -> span [ class "dropdown-item" ] [ text item ]) items
                ]
