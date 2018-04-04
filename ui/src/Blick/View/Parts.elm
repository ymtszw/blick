module Blick.View.Parts
    exposing
        ( link
        , onClickNoPropagate
        , onWithoutPropagate
        , withDisabled
        , authorTag
        , orgLocalNameOrEmail
        )

import Json.Decode as D exposing (Decoder)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events
import Html.Lazy as Z
import String.Extra as SE
import MD5
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


withDisabled : Bool -> List (Html.Attribute msg) -> List (Html.Attribute msg) -> List (Html.Attribute msg)
withDisabled disabled_ attrsWhenEnabled otherAttrs =
    if disabled_ then
        attribute "disabled" "disabled" :: otherAttrs
    else
        attrsWhenEnabled ++ otherAttrs


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
                    [ Z.lazy roundTagOfName name
                    , span
                        [ class "tag tag-button is-rounded"
                        , onWithoutPropagate "click" (authorTagClickDecoder anc matId (Just email))
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
                    , onWithoutPropagate "click" (authorTagClickDecoder anc matId Nothing)
                    ]
                    [ span [ class "fa fa-plus" ] []
                    , text "Add author"
                    ]
                ]


authorTagClickDecoder : Selector -> MatId -> Maybe String -> Decoder Msg
authorTagClickDecoder uniqueAncestor ((MatId id_) as matId) maybePrev =
    D.succeed <|
        InitiateEdit matId
            (Field "author_email" (Editable maybePrev UnTouched))
            (descendantOf uniqueAncestor (Selector (".tags[id='author-" ++ id_ ++ "']")))


orgLocalNameOrEmail : Email -> String
orgLocalNameOrEmail (Email email) =
    SE.replace atOrgDomain "" email


roundTagOfName : String -> Html Msg
roundTagOfName name =
    let
        hex =
            String.slice 0 6 (MD5.hex name)
    in
        span
            [ class "tag is-rounded"
            , style
                [ ( "background-color", "#" ++ hex )
                , ( "color", contrastingFontColor hex )
                ]
            ]
            [ text name ]


contrastingFontColor : String -> String
contrastingFontColor hex =
    let
        -- Taken from https://stackoverflow.com/a/1855903
        weightedSum =
            -- Just formatting using `0 +`
            0
                + (0.299 * toFloat (hexToInt (String.slice 0 2 hex)))
                + (0.587 * toFloat (hexToInt (String.slice 2 4 hex)))
                + (0.114 * toFloat (hexToInt (String.slice 4 6 hex)))

        perceptiveLuminance =
            1 - weightedSum / 255.0
    in
        if perceptiveLuminance < 0.5 then
            "#333333"
        else
            "#ffffff"


hexToInt : String -> Int
hexToInt hex =
    String.foldr
        (\char ( index, acc ) -> ( index + 1, acc + hexCharToInt char * (16 ^ index) ))
        ( 0, 0 )
        hex
        |> Tuple.second


hexCharToInt : Char -> Int
hexCharToInt hexChar =
    case hexChar of
        '0' ->
            0

        '1' ->
            1

        '2' ->
            2

        '3' ->
            3

        '4' ->
            4

        '5' ->
            5

        '6' ->
            6

        '7' ->
            7

        '8' ->
            8

        '9' ->
            9

        'a' ->
            10

        'b' ->
            11

        'c' ->
            12

        'd' ->
            13

        'e' ->
            14

        _ ->
            15
