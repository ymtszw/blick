module Util exposing (..)


isJust : Maybe a -> Bool
isJust m =
    case m of
        Just _ ->
            True

        Nothing ->
            False


split : Int -> List a -> List (List a)
split i list =
    case List.take i list of
        [] ->
            []

        chunk ->
            chunk :: split i (List.drop i list)
