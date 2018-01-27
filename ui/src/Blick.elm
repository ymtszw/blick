module Blick exposing (main)

import Html
import Rocket exposing ((=>))
import Blick.Type exposing (..)
import Blick.Client exposing (listMaterials)
import Blick.View exposing (view)


-- INIT


init : Flags -> ( Model, List (Cmd Msg) )
init flags =
    { materials = [] } => [ listMaterials ]



-- UPDATE


update : Msg -> Model -> ( Model, List (Cmd Msg) )
update msg model =
    case msg of
        ListMaterials (Ok ms) ->
            { model | materials = ms } => []

        ListMaterials (Err e) ->
            Debug.log "Http Error" e
                |> always model
                => []



-- MAIN


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init >> Rocket.batchInit
        , update = update >> Rocket.batchUpdate
        , subscriptions = always Sub.none
        , view = view
        }
