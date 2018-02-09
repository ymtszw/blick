module Blick exposing (main)

import Dict exposing (Dict)
import Regex
import Task
import Time
import Json.Decode as D
import Navigation exposing (Location)
import Rocket exposing ((=>))
import Blick.Constant exposing (..)
import Blick.Type exposing (..)
import Blick.Router exposing (route, goto)
import Blick.Client exposing (listMaterials)
import Blick.View exposing (view)


-- INIT


init : Flags -> Location -> ( Model, List (Cmd Msg) )
init materials location =
    let
        ms =
            materials
                |> D.decodeValue (D.dict (D.field "data" materialDecoder))
                |> Result.withDefault Dict.empty
    in
        { materials = ms
        , matches = []
        , filterInput = ""
        , carouselPage = 0
        , tablePage = 0
        , route = route location
        , exceptions =
            Dict.fromList
                [ 1000000000.0 => Exception "Test Test Test Long Long" "Dummy" [ "hoge", "fuga", "errrrrrrrror" ]
                , 10000000000.0 => Exception "Test" "Dummy" []
                , 100000000000.0 => Exception "Test" "Dummy" []
                , 1000000000000.0 => Exception "Test" "Dummy" []
                , 10000000000000.0 => Exception "Test" "Dummy" []
                ]
        }
            => [ listMaterials ]



-- UPDATE


update : Msg -> Model -> ( Model, List (Cmd Msg) )
update msg ({ materials, carouselPage, tablePage, exceptions } as model) =
    case msg of
        Loc location ->
            { model | route = route location } => []

        GoTo r ->
            let
                ( path, cmds ) =
                    goto r
            in
                model => (Navigation.newUrl path :: cmds)

        TimedErr err time ->
            { model | exceptions = Dict.insert time (fromHttpError err) exceptions } => []

        CloseErr time ->
            { model | exceptions = Dict.remove time exceptions } => []

        ClientRes (Ok (ListMaterials ms)) ->
            -- Caution: Members of FIRST dict has precedence at collision in Dict.union
            { model | materials = Dict.union ms materials } => []

        ClientRes (Ok (GetMaterial ( id, m ))) ->
            { model | materials = Dict.insert id m materials } => []

        ClientRes (Err err) ->
            model => [ Task.perform (TimedErr err) Time.now ]

        CarouselNext ->
            let
                max =
                    maxCarouselPage <| Dict.size materials
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

        TableNext ->
            let
                max =
                    maxTablePage <| Dict.size materials
            in
                if tablePage > max then
                    { model | tablePage = max } => []
                else if tablePage < max then
                    { model | tablePage = model.tablePage + 1 } => []
                else
                    model => []

        TablePrev ->
            if tablePage < 0 then
                { model | tablePage = 0 } => []
            else if tablePage > 0 then
                { model | tablePage = model.tablePage - 1 } => []
            else
                model => []

        Filter "" ->
            { model | matches = [], filterInput = "" } => []

        Filter input ->
            { model
                | matches = findMatchingIds materials input
                , filterInput = input
                , carouselPage = 0
                , tablePage = 0
            }
                => []


findMatchingIds : Dict String Material -> String -> List String
findMatchingIds materials input =
    input
        |> String.toLower
        |> Regex.split Regex.All whitespaces
        |> List.filter (not << String.isEmpty)
        |> findMatchingIdsImpl materials


whitespaces : Regex.Regex
whitespaces =
    Regex.regex "\\s+"


findMatchingIdsImpl : Dict String Material -> List String -> List String
findMatchingIdsImpl materials words =
    materials |> Dict.toList |> List.filterMap (maybeMatchingId words)


maybeMatchingId : List String -> ( String, Material ) -> Maybe String
maybeMatchingId words (( _, { excluded } ) as material) =
    if excluded then
        Nothing
    else
        List.foldl (maybeMatchingIdImpl material) Nothing words


maybeMatchingIdImpl : ( String, Material ) -> String -> Maybe String -> Maybe String
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
    Navigation.programWithFlags Loc
        { init = \flags location -> init flags location |> Rocket.batchInit
        , update = update >> Rocket.batchUpdate
        , subscriptions = always Sub.none
        , view = view
        }
