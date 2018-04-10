module Blick exposing (main)

import Dict
import Time
import Json.Decode as D
import Json.Decode.Extra exposing ((|:))
import Navigation exposing (Location)
import Window exposing (resizes)
import Rocket exposing ((=>))
import Blick.Type exposing (..)
import Blick.Constant exposing (debTick)
import Blick.Router exposing (route)
import Blick.Ports as Ports
import Blick.Keybinds as Keybinds
import Blick.Client exposing (listMaterials)
import Blick.Update exposing (update)
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
        , selectedSuggestion = Nothing
        , matches = []
        , filter = FilterState False ""
        , members = []
        , carouselPage = 0
        , tablePage = 0
        , route = route location
        , exceptions = Dict.empty
        , windowSize = ws
        , deb = Grounded
        }
            => [ listMaterials ]


fromFlags : Flags -> ( Window.Size, MaterialDict )
fromFlags flags =
    let
        dec =
            D.succeed (,)
                |: D.field "windowSize" (D.map2 Window.Size (D.field "width" D.int) (D.field "height" D.int))
                |: D.field "materials" matDictDecoder
    in
        flags
            |> D.decodeValue dec
            |> Result.withDefault ( fallbackSize, matDictEmpty )


fallbackSize : Window.Size
fallbackSize =
    Window.Size 800 600



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ resizes WindowSize
        , Keybinds.subscriptions model
        , Ports.listenEditorDOMRect StartEdit
        , debounceSub model
        ]


debounceSub : Model -> Sub Msg
debounceSub { deb } =
    case deb of
        Grounded ->
            Sub.none

        Excited 0 msg ->
            Sub.batch
                [ Time.every debTick (always DebDrop)
                , Time.every debTick (always msg)
                ]

        Excited remainingTicks msg ->
            Time.every debTick <| \_ -> DebTick (remainingTicks - 1) msg



-- MAIN


main : Program Flags Model Msg
main =
    Navigation.programWithFlags Loc
        { init = \flags location -> init flags location |> Rocket.batchInit
        , update = update >> Rocket.batchUpdate
        , subscriptions = subscriptions
        , view = view
        }
