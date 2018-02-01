module Blick.View.Table exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Lazy as Z
import Util
import Blick.Constant exposing (maxTablePage, rowPerTable, tablePerPage)
import Blick.Type exposing (Id(Id), Material, Msg(..), Url(..))
import Blick.View.Parts exposing (withDisabled)


view : Int -> List ( Id, Material ) -> Html Msg
view tablePage materials =
    div [ class "hero is-primary" ]
        [ div [ class "hero-body" ]
            [ div [ class "container carousel is-fullhd" ]
                [ tableNav tablePage (List.length materials)
                , materials
                    |> Util.split rowPerTable
                    |> Util.split tablePerPage
                    |> List.indexedMap (tablesOfPage tablePage)
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


tablesOfPage : Int -> Int -> List (List ( Id, Material )) -> Html Msg
tablesOfPage tablePage pageIndex materials =
    let
        isActive =
            if pageIndex == tablePage then
                style []
            else
                style [ ( "display", "none" ) ]
    in
        div [ class "carousel-item", isActive ]
            [ materials
                |> List.map tableColumn
                |> fillByDummyTable
                |> div [ class "columns" ]
            ]


tableColumn : List ( Id, Material ) -> Html Msg
tableColumn materials =
    div [ class "column is-half" ]
        [ table [ class "table is-striped is-hoverable is-fullwidth" ]
            [ materials
                |> List.map rowOfTable
                |> fillByDummyRow
                |> tbody []
            ]
        ]


rowOfTable : ( Id, Material ) -> Html Msg
rowOfTable ( Id id_, { title } ) =
    tr [ id id_ ]
        [ td [ class "is-paddingless" ] [ a [ class "text-nowrap", href <| "/" ++ id_ ] [ text title ] ]
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
