module Blick.Router exposing (route)

import Navigation exposing (Location)
import Blick.Type exposing (Route(..), Id(Id))


route : Location -> Route
route { pathname } =
    case split pathname of
        [] ->
            Root

        [ id ] ->
            Detail (Id id)

        _ ->
            NotFound


split : String -> List String
split pathname =
    pathname
        |> String.split "/"
        |> List.filter (not << String.isEmpty)
