module Blick.View.Parts
    exposing
        ( link
        , onClickNoPropagate
        , onSubmitNoPropagate
        , withDisabled
        , authorTag
        , orgLocalNameOrEmail
        )

import Char
import Json.Decode as D exposing (Decoder)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events
import String.Extra as SE
import Blick.Type exposing (Msg(..), Field, ClickPos, Url(Url), Email(Email))


link : Url -> Html.Attribute msg
link (Url url) =
    href url


onClickNoPropagate : (ClickPos -> msg) -> Html.Attribute msg
onClickNoPropagate msg =
    Html.Events.onWithOptions
        "click"
        (Html.Events.Options True True)
        (D.map msg domOriginDecoder)


domOriginDecoder : Decoder ClickPos
domOriginDecoder =
    D.map2 (,)
        (D.field "clientX" D.int)
        (D.field "clientY" D.int)


onSubmitNoPropagate : Decoder msg -> Html.Attribute msg
onSubmitNoPropagate dec =
    Html.Events.onWithOptions
        "submit"
        (Html.Events.Options True True)
        dec


withDisabled : Bool -> List (Html.Attribute msg) -> List (Html.Attribute msg)
withDisabled disabled_ others =
    if disabled_ then
        attribute "disabled" "disabled" :: others
    else
        others


authorTag : String -> Maybe Email -> Html Msg
authorTag id_ author_email =
    case author_email of
        Just (Email email) ->
            let
                name =
                    orgLocalNameOrEmail email
            in
                div [ class "tags has-addons is-pulled-right" ]
                    [ span [ class <| "tag is-rounded " ++ colorClassByName name ] [ text name ]
                    , span
                        [ class "tag tag-button is-rounded"
                        , onClickNoPropagate (StartEdit id_ (Field "author_email" email))
                        ]
                        [ span [ class "fa fa-pencil-alt" ] [] ]
                    ]

        Nothing ->
            span
                [ class "tag tag-button is-rounded is-pulled-right add-author"
                , onClickNoPropagate (StartEdit id_ (Field "author_email" ""))
                ]
                [ span [ class "fa fa-plus" ] []
                , text "Add author"
                ]


orgLocalNameOrEmail : String -> String
orgLocalNameOrEmail email =
    SE.replace "@access-company.com" "" email


colorClassByName : String -> String
colorClassByName name =
    name
        |> String.foldl (\char acc -> acc + Char.toCode char) 0
        |> (\sum -> rem sum 7)
        |> colorClassByNumber


colorClassByNumber : Int -> String
colorClassByNumber num =
    case num of
        0 ->
            "is-dark"

        1 ->
            "is-primary"

        2 ->
            "is-link"

        3 ->
            "is-info"

        4 ->
            "is-success"

        5 ->
            "is-warning"

        _ ->
            "is-danger"
