module Blick.Update exposing (update)

import Dict
import Regex
import Task
import Time
import Dom
import Navigation
import Window
import Rocket exposing ((=>))
import Blick.Type exposing (..)
import Blick.Router exposing (route, goto)
import Blick.Constant exposing (..)
import Blick.Client exposing (updateMaterialField, listMembers)
import Blick.Ports as Ports


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

        NoOp ->
            model => []

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
            { model | materials = matDictUnion ms materials } => []

        ClientRes (Ok (GetMaterial ( id, m ))) ->
            { model | materials = matDictInsert id m materials } => []

        ClientRes (Ok (UpdateMaterialField ( id, m ))) ->
            { model | materials = matDictInsert id m materials } => []

        ClientRes (Ok (ListMembers members)) ->
            { model | members = members } => []

        ClientRes (Err err) ->
            model => [ Task.perform (TimedErr err) Time.now ]

        CarouselNext ->
            let
                max =
                    maxCarouselPage windowSize.width (dictSize materials)
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
                    maxTablePage windowSize.width (dictSize materials)
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

        InitiateEdit ((MatId id_) as matId) field (Selector s) ->
            { model | toEdit = Just ( matId, field ) }
                => [ Ports.queryDOMOrigin ( id_, field, s ) ]

        StartEdit ( matId, field, pos ) ->
            { model | toEdit = Nothing, editing = Just ( matId, field, pos ) }
                => if field.name_ == "author_email" then
                    [ listMembers, Dom.focus (inputId matId field) |> Task.attempt (always NoOp) ]
                   else
                    [ Dom.focus (inputId matId field) |> Task.attempt (always NoOp) ]

        SubmitEdit id_ field ->
            { model | editing = Nothing }
                => [ updateMaterialField id_ field, Ports.unlockScroll () ]

        CancelEdit ->
            { model | editing = Nothing } => [ Ports.unlockScroll () ]


findMatchingIds : MaterialDict -> String -> List MatId
findMatchingIds materials input =
    input
        |> String.toLower
        |> Regex.split Regex.All whitespaces
        |> List.filter (not << String.isEmpty)
        |> findMatchingIdsImpl materials


whitespaces : Regex.Regex
whitespaces =
    Regex.regex "\\s+"


findMatchingIdsImpl : MaterialDict -> List String -> List MatId
findMatchingIdsImpl materials words =
    materials |> matDictToList |> List.filterMap (maybeMatchingId words)


maybeMatchingId : List String -> ( MatId, Material ) -> Maybe MatId
maybeMatchingId words (( _, { excluded } ) as material) =
    if excluded then
        Nothing
    else
        List.foldl (maybeMatchingIdImpl material) Nothing words


maybeMatchingIdImpl : ( MatId, Material ) -> String -> Maybe MatId -> Maybe MatId
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
