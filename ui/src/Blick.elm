module Blick exposing (main)

import Dict exposing (Dict)
import Json.Decode as D
import Json.Decode.Extra exposing ((|:))
import Navigation exposing (Location)
import Window exposing (resizes)
import Rocket exposing ((=>))
import Blick.Type exposing (..)
import Blick.Router exposing (route)
import Blick.Ports as Ports
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
        , toEdit = Nothing
        , editing = Nothing
        , matches = []
        , filterInput = ""
        , members = []
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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ resizes WindowSize

        -- Ideally, we want to subscribe `listenDOMOrigin` only when `queryDOMOrigin` is performed,
        -- though (inconveniently,) port response from JS coming faster than this function is evaluated again.
        , Ports.listenDOMOrigin StartEdit
        ]



-- MAIN


main : Program Flags Model Msg
main =
    Navigation.programWithFlags Loc
        { init = \flags location -> init flags location |> Rocket.batchInit
        , update = update >> Rocket.batchUpdate
        , subscriptions = subscriptions
        , view = view
        }
