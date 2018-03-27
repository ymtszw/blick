module Blick.Keybinds exposing (update, subscriptions)

import Keyboard exposing (KeyCode)
import Rocket exposing ((=>))
import Blick.Type exposing (..)


update : KeyCode -> Model -> ( Model, List (Cmd Msg) )
update _ model =
    model => []


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
