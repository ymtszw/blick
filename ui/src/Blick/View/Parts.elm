module Blick.View.Parts exposing (link, authorTag)

import Char
import Html exposing (..)
import Html.Attributes exposing (..)
import String.Extra as SE
import Blick.Type exposing (Msg(..), Url(Url), Email(Email))


link : Url -> Html.Attribute msg
link (Url url) =
    href url


authorTag : Maybe Email -> Html Msg
authorTag author_email =
    case author_email of
        Just (Email email) ->
            let
                name =
                    SE.replace "@access-company.com" "" email
            in
                span [ class <| "tag is-rounded is-pulled-right " ++ colorClassByName name ] [ text name ]

        Nothing ->
            text ""


colorClassByName : String -> String
colorClassByName name =
    name
        |> String.foldl (\char acc -> acc + Char.toCode char) 0
        |> (\sum -> rem sum 8)
        |> colorClassByNumber


colorClassByNumber : Int -> String
colorClassByNumber num =
    case num of
        0 ->
            "is-dark"

        1 ->
            "is-light"

        2 ->
            "is-primary"

        3 ->
            "is-link"

        4 ->
            "is-info"

        5 ->
            "is-success"

        6 ->
            "is-warning"

        _ ->
            "is-danger"
