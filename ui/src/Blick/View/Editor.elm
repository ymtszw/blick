module Blick.View.Editor exposing (modal)

import Html exposing (..)
import Html.Attributes exposing (..)
import Blick.Type exposing (Msg(..), Field)
import Blick.View.Parts exposing (onClickNoPropagate)


modal : String -> Field -> Html Msg
modal _ _ =
    div [ class "modal is-active" ]
        [ div [ class "modal-background", onClickNoPropagate (\_ -> CancelEdit) ] []
        , button [ class "modal-close is-large", attribute "aria-label" "close", onClickNoPropagate (\_ -> CancelEdit) ] []
        ]
