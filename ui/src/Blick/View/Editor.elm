module Blick.View.Editor exposing (modal)

import Html exposing (..)
import Html.Attributes exposing (..)
import Window
import Blick.Type exposing (Msg(..), Field, ClickPos)
import Blick.View.Parts exposing (onClickNoPropagate)


modal : Window.Size -> ( String, Field, ClickPos ) -> Html Msg
modal _ _ =
    div [ class "modal is-active" ]
        [ div [ class "modal-background", onClickNoPropagate (\_ -> CancelEdit) ] []
        , button [ class "modal-close is-large", attribute "aria-label" "close", onClickNoPropagate (\_ -> CancelEdit) ] []
        ]
