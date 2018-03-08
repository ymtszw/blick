module Blick.View.Detail exposing (modal)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Lazy as Z
import Blick.Type exposing (Msg(..), Route(..), Material, Url(Url))
import Blick.View.Parts exposing (..)


modal : String -> Material -> Html Msg
modal id_ material =
    div [ class "modal is-active" ]
        [ div [ class "modal-background", onClickNoPropagate (GoTo Root) ] []
        , div [ class "hero is-light" ]
            [ div [ class "hero-body" ]
                [ div [ class "container is-fullhd" ]
                    [ detailContents id_ material
                    ]
                ]
            ]
        , button [ class "modal-close is-large", attribute "aria-label" "close", onClickNoPropagate (GoTo Root) ] []
        ]


detailContents : String -> Material -> Html Msg
detailContents id_ { title, url, thumbnail_url, author_email } =
    div [ class "columns" ]
        [ div [ class "column is-two-thirds" ]
            [ a [ link url, target "_blank" ]
                [ detailThumbnail thumbnail_url
                ]
            ]
        , div [ class "column" ]
            [ h1 [ class "title" ] [ text title ]
            , div [ class "tags" ] [ Z.lazy2 authorTag id_ author_email ]
            ]
        ]


detailThumbnail : Maybe Url -> Html Msg
detailThumbnail maybeThumbnailUrl =
    case maybeThumbnailUrl of
        Just (Url thumbnailUrl) ->
            figure [ class "image is-16by9" ]
                [ img [ src thumbnailUrl ] []
                , div [ class "colmuns is-overlay" ]
                    [ div [ class "column" ] [ i [ class "fa fa-external-link-alt fa-5x" ] [] ]
                    ]
                ]

        Nothing ->
            figure [ class "image is-16by9" ]
                [ h1 [ class "title" ] [ text "No Thumbnail" ] ]
