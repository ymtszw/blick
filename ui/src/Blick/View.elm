module Blick.View exposing (..)

import Html exposing (..)
import Blick.Type exposing (Model, Msg(..))


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "Hey yo!!" ]
        , p [] [ text "from Elm" ]
        ]
