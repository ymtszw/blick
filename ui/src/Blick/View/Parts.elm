module Blick.View.Parts
    exposing
        ( link
        , onClickNoPropagate
        , onWithoutPropagate
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
import Blick.Constant exposing (atOrgDomain)
import Blick.Type exposing (..)


link : Url -> Html.Attribute msg
link (Url url) =
    href url


onClickNoPropagate : msg -> Html.Attribute msg
onClickNoPropagate msg =
    Html.Events.onWithOptions
        "click"
        (Html.Events.Options True True)
        (D.succeed msg)


onWithoutPropagate : String -> Decoder msg -> Html.Attribute msg
onWithoutPropagate event dec =
    Html.Events.onWithOptions
        event
        (Html.Events.Options True True)
        dec


withDisabled : Bool -> List (Html.Attribute msg) -> List (Html.Attribute msg)
withDisabled disabled_ others =
    if disabled_ then
        attribute "disabled" "disabled" :: others
    else
        others


authorTag : Selector -> MatId -> Maybe Email -> Html Msg
authorTag anc ((MatId id_) as matId) author_email =
    case author_email of
        Just (Email email) ->
            let
                name =
                    orgLocalNameOrEmail (Email email)
            in
                div
                    [ class "tags has-addons is-pulled-right"
                    , id <| "author-" ++ id_
                    ]
                    [ span [ class <| "tag is-rounded " ++ colorClassByName name ] [ text name ]
                    , span
                        [ class "tag tag-button is-rounded"
                        , onWithoutPropagate "click" (authorTagClickDecoder anc matId email)
                        ]
                        [ span [ class "fa fa-pencil-alt" ] [] ]
                    ]

        Nothing ->
            div
                [ class "tags is-pulled-right"
                , id <| "author-" ++ id_
                ]
                [ span
                    [ class "tag tag-button is-rounded add-author"
                    , onWithoutPropagate "click" (authorTagClickDecoder anc (MatId id_) "")
                    ]
                    [ span [ class "fa fa-plus" ] []
                    , text "Add author"
                    ]
                ]


authorTagClickDecoder : Selector -> MatId -> String -> Decoder Msg
authorTagClickDecoder uniqueAncestor ((MatId id_) as matId) currentValue =
    D.succeed <|
        InitiateEdit matId
            (Field "author_email" currentValue)
            (descendantOf uniqueAncestor (Selector (".tags[id='author-" ++ id_ ++ "']")))


orgLocalNameOrEmail : Email -> String
orgLocalNameOrEmail (Email email) =
    SE.replace atOrgDomain "" email


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
