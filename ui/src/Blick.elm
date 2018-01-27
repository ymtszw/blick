module Blick exposing (main)

import Html
import Rocket exposing ((=>))
import Blick.Type exposing (..)
import Blick.View exposing (view)


-- INIT


init : Flags -> ( Model, List (Cmd Msg) )
init flags =
    { materials = [] } => []



-- UPDATE


update : Msg -> Model -> ( Model, List (Cmd Msg) )
update msg model =
    model => []



-- MAIN


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init >> Rocket.batchInit
        , update = update >> Rocket.batchUpdate
        , subscriptions = always Sub.none
        , view = view
        }
