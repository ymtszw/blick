module Blick.View.Table exposing (view)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Lazy as Z
import Util
import Blick.Constant exposing (maxTablePage, rowPerTable, tablePerPage)
import Blick.Type exposing (Material, Msg(..), Url(..))
import Blick.View.Parts exposing (withDisabled, authorTag)


view : Int -> Dict String Material -> Html Msg
view tablePage materials =
    div [ class "hero is-primary" ]
        [ div [ class "hero-body" ]
            [ div [ class "container carousel is-fullhd" ]
                [ tableNav tablePage (Dict.size materials)
                , materials
                    |> Dict.toList
                    |> Util.split rowPerTable
                    |> Util.split tablePerPage
                    |> List.indexedMap (Z.lazy3 tablesOfPage tablePage)
                    |> fillByDummyPage
                    |> div [ class "carousel-container" ]
                ]
            ]
        ]


tableNav : Int -> Int -> Html Msg
tableNav tablePage numberOfMaterials =
    nav
        [ class "carousel-navigation pagination is-centered"
        , attribute "role" "navigation"
        , attribute "aria-label" "pagination"
        ]
        [ button (withDisabled (tablePage <= 0) [ class "pagination-previous", onClick TablePrev ])
            [ i [ class "fa fa-chevron-left" ] [] ]
        , button (withDisabled (tablePage >= maxTablePage numberOfMaterials) [ class "pagination-next", onClick TableNext ])
            [ i [ class "fa fa-chevron-right" ] [] ]
        ]


tablesOfPage : Int -> Int -> List (List ( String, Material )) -> Html Msg
tablesOfPage tablePage pageIndex materials =
    if pageIndex == tablePage then
        div [ class "carousel-item" ]
            [ materials
                |> List.map tableColumn
                |> fillByDummyTable
                |> div [ class "columns" ]
            ]
    else
        div [ class "carousel-item", style [ ( "display", "none" ) ] ] []


tableColumn : List ( String, Material ) -> Html Msg
tableColumn materials =
    div [ class "column is-half" ]
        [ table [ class "table is-striped is-hoverable is-fullwidth" ]
            [ materials
                |> List.map rowOfTable
                |> fillByDummyRow
                |> tbody []
            ]
        ]


rowOfTable : ( String, Material ) -> Html Msg
rowOfTable ( id_, { title, author_email } ) =
    tr [ id id_ ]
        [ td [ class "is-paddingless" ]
            [ a [ class "text-nowrap", href <| "/" ++ id_ ]
                [ text title
                , authorTag author_email
                ]
            ]
        ]


fillByDummyPage : List (Html Msg) -> List (Html Msg)
fillByDummyPage pages =
    case pages of
        [] ->
            [ Z.lazy3 tablesOfPage 0 0 [] ]

        _ ->
            pages


fillByDummyTable : List (Html Msg) -> List (Html Msg)
fillByDummyTable tables =
    case tables of
        [] ->
            List.repeat 2 <| tableColumn []

        [ _ ] ->
            tables ++ [ tableColumn [] ]

        _ ->
            tables


fillByDummyRow : List (Html Msg) -> List (Html Msg)
fillByDummyRow rows =
    let
        numOfRows =
            List.length rows
    in
        if rowPerTable > numOfRows then
            rows ++ List.repeat (rowPerTable - numOfRows) dummyRow
        else
            rows


dummyRow : Html Msg
dummyRow =
    tr [] [ td [] [ text "\x3000" ] ]
