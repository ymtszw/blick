module Blick.Router exposing (route)

import Navigation exposing (Location)
import Blick.Type exposing (Route(..), Msg(..))
import Blick.Client exposing (getMaterial)


route : Location -> ( Route, List (Cmd Msg) )
route { pathname } =
    case split pathname of
        [] ->
            ( Root, [ Cmd.none ] )

        [ id ] ->
            ( Detail id, [ getMaterial id ] )

        _ ->
            ( NotFound, [ Cmd.none ] )


split : String -> List String
split pathname =
    pathname
        |> String.split "/"
        |> List.filter (not << String.isEmpty)
