module Blick.Router exposing (route, goto)

import Navigation exposing (Location)
import Blick.Type exposing (Route(..), Msg(..))
import Blick.Ports exposing (lockScroll, unlockScroll)
import Blick.Client exposing (getMaterial)


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


goto : Route -> ( String, List (Cmd Msg) )
goto route =
    case route of
        Root ->
            ( "/", [ unlockScroll () ] )

        Detail id ->
            ( "/" ++ id, [ getMaterial id, lockScroll () ] )

        NotFound ->
            -- Should not happen
            ( "/", [ Cmd.none ] )
