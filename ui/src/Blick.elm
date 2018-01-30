module Blick exposing (main)

import Html
import Rocket exposing ((=>))
import Blick.Type exposing (..)
import Blick.Client exposing (listMaterials)
import Blick.View exposing (view)


-- INIT


init : Flags -> ( Model, List (Cmd Msg) )
init flags =
    { materials = []
    , carouselPage = 0
    }
        => [ listMaterials ]



-- UPDATE


update : Msg -> Model -> ( Model, List (Cmd Msg) )
update msg ({ materials, carouselPage } as model) =
    case msg of
        ListMaterials (Ok ms) ->
            { model | materials = ms } => []

        ListMaterials (Err e) ->
            Debug.log "Http Error" e
                |> always model
                => []

        CarouselNext ->
            let
                max =
                    List.length materials
            in
                if carouselPage > max then
                    { model | carouselPage = max } => []
                else if carouselPage < max then
                    { model | carouselPage = model.carouselPage + 1 } => []
                else
                    model => []

        CarouselPrev ->
            if carouselPage < 0 then
                { model | carouselPage = 0 } => []
            else if carouselPage > 0 then
                { model | carouselPage = model.carouselPage - 1 } => []
            else
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
