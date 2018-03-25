module Blick.Router exposing (route, goto)

import Navigation exposing (Location)
import Blick.Type exposing (Route(..), Msg(..), MatId(MatId))
import Blick.Ports exposing (lockScroll, unlockScroll)
import Blick.Client exposing (getMaterial)


route : Location -> Route
route { pathname } =
    case split pathname of
        [] ->
            Root

        [ id ] ->
            Detail (MatId id)

        _ ->
            NotFound


split : String -> List String
split pathname =
    pathname
        |> String.split "/"
        |> List.filter (not << String.isEmpty)


goto : Route -> ( String, List (Cmd Msg) )
goto route =
    case route of
        Root ->
            ( "/", [ unlockScroll () ] )

        Detail (MatId id) ->
            ( "/" ++ id, [ getMaterial (MatId id), lockScroll () ] )

        NotFound ->
            -- Should not happen
            ( "/", [ Cmd.none ] )
