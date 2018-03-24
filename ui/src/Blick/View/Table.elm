module Blick.View.Table exposing (view)

import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Lazy as Z
import Util
import Blick.Constant exposing (maxTablePage, rowPerTable, tablePerPage)
import Blick.Type exposing (Model, Material, Msg(..), Route(..), Url(..), selector)
import Blick.View.Parts exposing (..)


view : Model -> Html Msg
view { materials, windowSize, tablePage } =
    let
        tpp =
            tablePerPage windowSize.width
    in
        div [ class "hero is-primary" ]
            [ div [ class "hero-body" ]
                [ div [ class "container tables is-fullhd" ]
                    [ tableNav (maxTablePage windowSize.width (Dict.size materials)) tablePage
                    , materials
                        |> Dict.toList
                        |> Util.split rowPerTable
                        |> Util.split tpp
                        |> List.indexedMap (tablesOfPage tpp tablePage)
                        |> fillByDummyPage tpp
                        |> div [ class "tables-container" ]
                    ]
                ]
            ]


tableNav : Int -> Int -> Html Msg
tableNav max tablePage =
    nav
        [ class "tables-navigation pagination is-centered"
        , attribute "role" "navigation"
        , attribute "aria-label" "pagination"
        ]
        [ button (withDisabled (tablePage <= 0) [ class "pagination-previous", onClick TablePrev ])
            [ i [ class "fa fa-chevron-left" ] [] ]
        , button (withDisabled (tablePage >= max - 1) [ class "pagination-next", onClick TableNext ])
            [ i [ class "fa fa-chevron-right" ] [] ]
        ]


tablesOfPage : Int -> Int -> Int -> List (List ( String, Material )) -> Html Msg
tablesOfPage tpp tablePage pageIndex materials =
    if pageIndex == tablePage then
        div [ class "tables-item" ]
            [ materials
                |> List.map tableColumn
                |> fillByDummyTable tpp
                |> div [ class "columns" ]
            ]
    else
        div [ class "tables-item", style [ ( "display", "none" ) ] ] []


tableColumn : List ( String, Material ) -> Html Msg
tableColumn materials =
    div [ class "column is-half" ]
        [ table [ class "table is-striped is-hoverable is-fullwidth" ]
            [ materials
                |> List.map (Z.lazy rowOfTable)
                |> fillByDummyRow
                |> tbody []
            ]
        ]


rowOfTable : ( String, Material ) -> Html Msg
rowOfTable ( id_, { title, author_email } ) =
    tr [ id id_ ]
        [ td [ class "is-paddingless" ]
            [ a [ class "text-nowrap", href ("/" ++ id_), onClickNoPropagate (GoTo (Detail id_)) ]
                [ text title
                , authorTag (selector ("tr[id='" ++ id_ ++ "']")) id_ author_email
                ]
            ]
        ]


fillByDummyPage : Int -> List (Html Msg) -> List (Html Msg)
fillByDummyPage tpp pages =
    case pages of
        [] ->
            [ tablesOfPage tpp 0 0 [] ]

        _ ->
            pages


fillByDummyTable : Int -> List (Html Msg) -> List (Html Msg)
fillByDummyTable tpp tables =
    case tables of
        [] ->
            List.repeat tpp (Z.lazy tableColumn [])

        [ _ ] ->
            if tpp == 1 then
                tables
            else
                tables ++ [ Z.lazy tableColumn [] ]

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
