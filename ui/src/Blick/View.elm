module Blick.View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Util
import Blick.Type exposing (Model, Msg(..), Route(..), Id(Id), Material)
import Blick.View.Hero as Hero
import Blick.View.Carousel as Carousel
import Blick.View.Table as Table
import Blick.View.Detail as Detail


view : Model -> Html Msg
view { materials, carouselPage, tablePage, matches, filterInput, route } =
    let
        ( withThumbs, withouts ) =
            materials
                |> applyFilter matches
                |> List.partition (\( _, { thumbnail_url } ) -> Util.isJust thumbnail_url)
    in
        section [ class "main" ]
            [ modalByRoute materials route
            , Hero.view matches filterInput
            , Carousel.view carouselPage withThumbs
            , Table.view tablePage withouts
            ]


applyFilter : List Id -> List ( Id, Material ) -> List ( Id, Material )
applyFilter matches materials =
    case matches of
        [] ->
            materials

        _ ->
            List.filter (\( id, _ ) -> List.member id matches) materials


modalByRoute : List ( Id, Material ) -> Route -> Html Msg
modalByRoute materials route =
    case route of
        Detail id ->
            case findMaterialById materials id of
                Just material ->
                    Detail.modal material

                Nothing ->
                    text ""

        _ ->
            text ""


findMaterialById : List ( Id, Material ) -> Id -> Maybe Material
findMaterialById materials targetId =
    case materials of
        [] ->
            Nothing

        ( id, material ) :: ms ->
            if id == targetId then
                Just material
            else
                findMaterialById ms targetId
