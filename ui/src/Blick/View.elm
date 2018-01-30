module Blick.View exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Util
import Blick.Constant exposing (..)
import Blick.Type exposing (Model, Msg(..), Id(Id), Material, Url(Url))


view : Model -> Html Msg
view { materials, carouselPage, matches, filterInput } =
    let
        ( withThumbs, withouts ) =
            materials
                |> applyFilter matches
                |> List.partition (\( _, { thumbnail_url } ) -> Util.isJust thumbnail_url)
    in
        section [ class "main" ]
            [ hero matches filterInput
            , carousel carouselPage withThumbs
            ]


applyFilter : List Id -> List ( Id, Material ) -> List ( Id, Material )
applyFilter matches materials =
    case matches of
        [] ->
            materials

        _ ->
            List.filter (\( id, _ ) -> List.member id matches) materials


hero : List Id -> String -> Html Msg
hero matches input_ =
    div [ class "hero is-primary" ]
        [ div [ class "hero-body" ]
            [ div [ class "container" ]
                [ div [ class "columns" ]
                    [ div [ class "column is-half is-left" ]
                        [ h1 [ class "title" ] [ text "Blick" ]
                        ]
                    , div [ class "column" ]
                        [ filter matches input_ ]
                    ]
                ]
            ]
        ]


filter : List Id -> String -> Html Msg
filter matches input_ =
    div [ class "field is-expanded" ]
        [ div [ class "control has-icons-left has-icons-right" ]
            [ input [ type_ "text", placeholder "OR filter", class <| "input is-flat" ++ filterInputColor matches input_, onInput Filter ] []
            , span [ class "icon is-small is-left" ] [ i [ class "fa fa-filter" ] [] ]
            , filterInputResult matches input_
            ]
        ]


filterInputColor : List Id -> String -> String
filterInputColor matches input_ =
    if not (String.isEmpty input_) && List.isEmpty matches then
        " is-danger"
    else
        ""


filterInputResult : List Id -> String -> Html Msg
filterInputResult matches input_ =
    case input_ of
        "" ->
            text ""

        _ ->
            case matches of
                [] ->
                    span [ class "icon is-small is-right" ] [ i [ class "fa fa-warning" ] [] ]

                _ ->
                    span [ class "icon is-small is-right" ] [ text <| toString <| List.length matches ]


carousel : Int -> List ( Id, Material ) -> Html Msg
carousel carouselPage materials =
    div [ class "hero is-info" ]
        [ div [ class "hero-body" ]
            [ div [ class "container carousel is-fullhd" ]
                [ materials
                    |> Util.split tilePerRow
                    |> Util.split rowPerPage
                    |> List.indexedMap (carouselItem carouselPage)
                    |> fillByDummyPage
                    |> div [ class "carousel-container" ]
                , carouselNav carouselPage (List.length materials)
                ]
            ]
        ]


fillByDummyPage : List (Html Msg) -> List (Html Msg)
fillByDummyPage pages =
    case pages of
        _ :: _ ->
            pages

        _ ->
            fillByDummyRow []


carouselNav : Int -> Int -> Html Msg
carouselNav carouselPage numberOfPages =
    nav
        [ class "carousel-navigation pagination is-centered"
        , attribute "role" "navigation"
        , attribute "aria-label" "pagination"
        ]
        [ button (disabled (carouselPage <= 0) [ class "pagination-previous", onClick CarouselPrev ])
            [ i [ class "fa fa-chevron-left" ] [] ]
        , button (disabled (carouselPage >= maxCarouselPage numberOfPages) [ class "pagination-next", onClick CarouselNext ])
            [ i [ class "fa fa-chevron-right" ] [] ]
        ]


disabled : Bool -> List (Html.Attribute msg) -> List (Html.Attribute msg)
disabled disabled_ others =
    if disabled_ then
        attribute "disabled" "disabled" :: others
    else
        others


carouselItem : Int -> Int -> List (List ( Id, Material )) -> Html Msg
carouselItem materialPage pageIndex materialsByPage =
    let
        isActive =
            if pageIndex == materialPage then
                style []
            else
                style [ ( "display", "none" ) ]
    in
        materialsByPage
            |> List.map tileRow
            |> fillByDummyRow
            |> div [ class "carousel-item", isActive ]


tileRow : List ( Id, Material ) -> Html Msg
tileRow materialsUpto4 =
    div [ class "columns" ] <|
        List.map tileColumn materialsUpto4


tileColumn : ( Id, Material ) -> Html Msg
tileColumn ( id, material ) =
    div [ class <| "column" ++ columnSizeClass ]
        [ a [ link material.url ]
            [ article [ class "material card", key id ]
                [ div [ class "card-image" ]
                    [ thumbnail material.thumbnail_url
                    ]
                , div [ class "card-content" ]
                    [ p [ class "is-size-7 text-nowrap" ] [ text material.title ]
                    ]
                ]
            ]
        ]


fillByDummyRow : List (Html Msg) -> List (Html Msg)
fillByDummyRow rows =
    case rows of
        [] ->
            [ dummyRow, dummyRow, dummyRow ]

        [ _ ] ->
            rows ++ [ dummyRow, dummyRow ]

        [ _, _ ] ->
            rows ++ [ dummyRow ]

        _ ->
            rows


dummyRow : Html Msg
dummyRow =
    div [ class "columns is-invisible" ]
        [ div [ class <| "column" ++ columnSizeClass ]
            [ article [ class "material card" ]
                [ div [ class "card-image" ] [ thumbnail Nothing ]
                , div [ class "card-content" ]
                    [ p [ class "is-size-7 text-nowrap" ] [ text "Dummy" ]
                    ]
                ]
            ]
        ]


{-| Must fix size, otherwise it grows when there aren't enough columns
-}
columnSizeClass : String
columnSizeClass =
    " is-" ++ toString (bulmaColumnScaleMax // tilePerRow)


key : Id -> Html.Attribute msg
key (Id id_) =
    id id_


link : Url -> Html.Attribute msg
link (Url url) =
    href url


thumbnail : Maybe Url -> Html Msg
thumbnail maybeUrl =
    case maybeUrl of
        Just (Url url) ->
            figure [ class "image is-16by9" ]
                [ img [ src url ] [] ]

        Nothing ->
            figure [ class "image is-16by9" ]
                []
