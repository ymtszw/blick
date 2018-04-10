module Blick.Update exposing (update)

import Dict
import Process
import Regex
import Task
import Time
import Dom
import Window
import Rocket exposing ((=>))
import Blick.Type exposing (..)
import Blick.Router exposing (route, goto)
import Blick.Constant exposing (..)
import Blick.Client exposing (updateMaterialField, listMembers)
import Blick.Ports as Ports


update : Msg -> Model -> ( Model, List (Cmd Msg) )
update msg ({ materials, filter, exceptions } as model) =
    case msg of
        Loc location ->
            { model | route = route location } => []

        GoTo r ->
            model => goto r

        NoOp ->
            model => []

        WindowSize newSize ->
            resetPagesAtWindowSizeThresholds model newSize => []

        TimedErr err time ->
            { model | exceptions = Dict.insert time (fromHttpError err) exceptions } => []

        CloseErr time ->
            { model | exceptions = Dict.update time (Maybe.map (\e -> { e | isOpen = False })) exceptions }
                => [ Process.sleep exceptionCloseFullMs |> Task.perform (always (PurgeErr time)) ]

        PurgeErr time ->
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

        SetCarouselPage cPage ->
            { model | carouselPage = cPage } => []

        SetTablePage tPage ->
            { model | tablePage = tPage } => []

        InputFilter "" ->
            { model | matches = [], filter = { filter | value_ = "" } } => []

        InputFilter input ->
            { model | matches = findMatchingIds materials input, filter = { filter | value_ = input }, carouselPage = 0, tablePage = 0 }
                => []

        DebLift ticksToHold msg ->
            { model | deb = Excited ticksToHold msg } => []

        DebTick remainingTicks msg ->
            { model | deb = Excited remainingTicks msg } => []

        DebDrop ->
            { model | deb = Grounded } => []

        SetFilterFocus focused ->
            { model | filter = { filter | focused = focused } } => []

        FocusFilter focusing ->
            model => [ toggleFocus filterBoxId focusing ]

        InitiateEdit matId field selector ->
            model => [ Ports.queryEditorDOMRect matId field selector ]

        StartEdit matId field domRect ->
            { model | editing = Just (EditState matId field domRect), selectedSuggestion = Nothing }
                => (extraCmdsByEditingField field ++ [ toggleFocus (inputId matId field) True ])

        InputEdit ({ field } as editState) newEditable ->
            { model | editing = Just { editState | field = { field | value_ = newEditable } }, selectedSuggestion = Nothing }
                => []

        CompleteEdit ({ matId, field } as editState) newEditable ->
            { model | editing = Just { editState | field = { field | value_ = newEditable } }, selectedSuggestion = Nothing }
                => [ toggleFocus (inputId matId field) True ]

        SelectSuggestion index ->
            { model | selectedSuggestion = Just index } => []

        SubmitEdit matId field ->
            { model | editing = Nothing, selectedSuggestion = Nothing }
                => [ updateMaterialField matId field, Ports.unlockScroll () ]

        CancelEdit ->
            { model | editing = Nothing, selectedSuggestion = Nothing }
                => [ Ports.unlockScroll () ]


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


resetPagesAtWindowSizeThresholds : Model -> Window.Size -> Model
resetPagesAtWindowSizeThresholds ({ windowSize } as model) newSize =
    if crossedMobileMax windowSize newSize then
        { model | windowSize = newSize, carouselPage = 0, tablePage = 0 }
    else if crossedSingleColumnMax windowSize newSize then
        { model | windowSize = newSize, carouselPage = 0 }
    else
        { model | windowSize = newSize }


crossedMobileMax : Window.Size -> Window.Size -> Bool
crossedMobileMax oldSize newSize =
    (oldSize.width <= mobileMaxWidthPx && newSize.width > mobileMaxWidthPx)
        || (oldSize.width > mobileMaxWidthPx && newSize.width <= mobileMaxWidthPx)


crossedSingleColumnMax : Window.Size -> Window.Size -> Bool
crossedSingleColumnMax oldSize newSize =
    (oldSize.width <= singleColumnMaxWidthPx && newSize.width > singleColumnMaxWidthPx)
        || (oldSize.width > singleColumnMaxWidthPx && newSize.width <= singleColumnMaxWidthPx)


extraCmdsByEditingField : Field -> List (Cmd Msg)
extraCmdsByEditingField { name_ } =
    if name_ == "author_email" then
        [ listMembers ]
    else
        []


toggleFocus : String -> Bool -> Cmd Msg
toggleFocus elementId focusing =
    Task.attempt (always NoOp) <|
        if focusing then
            Dom.focus elementId
        else
            Dom.blur elementId
