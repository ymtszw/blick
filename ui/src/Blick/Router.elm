module Blick.Router exposing (route)

import Navigation exposing (Location)
import Blick.Type exposing (Route(..))


route : Location -> Route
route { pathname } =
    case split pathname of
        [] ->
            Root

        [ id ] ->
            Detail id

        _ ->
            NotFound


split : String -> List String
split pathname =
    pathname
        |> String.split "/"
        |> List.filter (not << String.isEmpty)
