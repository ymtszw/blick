module Blick exposing (main)

import Regex
import Html
import Rocket exposing ((=>))
import Blick.Constant exposing (..)
import Blick.Type exposing (..)
import Blick.Client exposing (listMaterials)
import Blick.View exposing (view)


-- INIT


init : Flags -> ( Model, List (Cmd Msg) )
init flags =
    { materials = []
    , matches = []
    , filterInput = ""
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
                    maxCarouselPage <| List.length materials
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

        Filter "" ->
            { model | matches = [], filterInput = "" } => []

        Filter input ->
            { model
                | matches = findMatchingIds materials input
                , filterInput = input
                , carouselPage = 0
            }
                => []


findMatchingIds : List ( Id, Material ) -> String -> List Id
findMatchingIds materials input =
    input
        |> String.toLower
        |> Regex.split Regex.All (Regex.regex "\\s+")
        |> findMatchingIdsImpl materials


findMatchingIdsImpl : List ( Id, Material ) -> List String -> List Id
findMatchingIdsImpl materials words =
    List.filterMap (maybeMatchingId words) materials


maybeMatchingId : List String -> ( Id, Material ) -> Maybe Id
maybeMatchingId words (( _, { excluded } ) as material) =
    if excluded then
        Nothing
    else
        List.foldl (maybeMatchingIdImpl material) Nothing words


maybeMatchingIdImpl : ( Id, Material ) -> String -> Maybe Id -> Maybe Id
maybeMatchingIdImpl ( id, { title, author_email } ) word maybeId =
    case maybeId of
        Just _ ->
            maybeId

        Nothing ->
            if String.contains word <| String.toLower title then
                Just id
            else
                Maybe.andThen
                    (\(Email email) ->
                        if String.contains word <| String.toLower email then
                            Just id
                        else
                            Nothing
                    )
                    author_email



-- MAIN


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init >> Rocket.batchInit
        , update = update >> Rocket.batchUpdate
        , subscriptions = always Sub.none
        , view = view
        }
