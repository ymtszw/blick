module Blick exposing (main)

import Dict exposing (Dict)
import Regex
import Task
import Time
import Json.Decode as D
import Json.Decode.Extra exposing ((|:))
import Navigation exposing (Location)
import Window exposing (resizes)
import Rocket exposing ((=>))
import Blick.Constant exposing (..)
import Blick.Type exposing (..)
import Blick.Router exposing (route, goto)
import Blick.Client exposing (listMaterials)
import Blick.View exposing (view)


-- INIT


init : Flags -> Location -> ( Model, List (Cmd Msg) )
init flags location =
    let
        ( ws, ms ) =
            fromFlags flags
    in
        { materials = ms
        , editing = Nothing
        , matches = []
        , filterInput = ""
        , carouselPage = 0
        , tablePage = 0
        , route = route location
        , exceptions = Dict.empty
        , windowSize = ws
        }
            => [ listMaterials ]


fromFlags : Flags -> ( Window.Size, Dict String Material )
fromFlags flags =
    let
        dec =
            D.succeed (,)
                |: D.field "windowSize" (D.map2 Window.Size (D.field "width" D.int) (D.field "height" D.int))
                |: D.field "materials" (D.dict (D.field "data" materialDecoder))
    in
        flags
            |> D.decodeValue dec
            |> Result.withDefault ( fallbackSize, Dict.empty )


fallbackSize : Window.Size
fallbackSize =
    Window.Size 800 600



-- UPDATE


update : Msg -> Model -> ( Model, List (Cmd Msg) )
update msg ({ materials, carouselPage, tablePage, exceptions, windowSize } as model) =
    case msg of
        Loc location ->
            { model | route = route location } => []

        GoTo r ->
            let
                ( path, cmds ) =
                    goto r
            in
                model => (Navigation.newUrl path :: cmds)

        WindowSize newSize ->
            if crossedMobileMax windowSize newSize then
                { model | windowSize = newSize, carouselPage = 0, tablePage = 0 } => []
            else if crossedSingleColumnMax windowSize newSize then
                { model | windowSize = newSize, carouselPage = 0 } => []
            else
                { model | windowSize = newSize } => []

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
                    maxCarouselPage windowSize.width (Dict.size materials)
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
                    maxTablePage windowSize.width (Dict.size materials)
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

        StartEdit id_ field pos ->
            { model | editing = Just ( id_, field, pos ) } => []

        CancelEdit ->
            { model | editing = Nothing } => []


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


crossedMobileMax : Window.Size -> Window.Size -> Bool
crossedMobileMax oldSize newSize =
    (oldSize.width <= mobileMaxWidthPx && newSize.width > mobileMaxWidthPx)
        || (oldSize.width > mobileMaxWidthPx && newSize.width <= mobileMaxWidthPx)


crossedSingleColumnMax : Window.Size -> Window.Size -> Bool
crossedSingleColumnMax oldSize newSize =
    (oldSize.width <= singleColumnMaxWidthPx && newSize.width > singleColumnMaxWidthPx)
        || (oldSize.width > singleColumnMaxWidthPx && newSize.width <= singleColumnMaxWidthPx)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch [ resizes WindowSize ]



-- MAIN


main : Program Flags Model Msg
main =
    Navigation.programWithFlags Loc
        { init = \flags location -> init flags location |> Rocket.batchInit
        , update = update >> Rocket.batchUpdate
        , subscriptions = subscriptions
        , view = view
        }
