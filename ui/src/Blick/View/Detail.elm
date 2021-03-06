module Blick.View.Detail exposing (modal)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Lazy as Z
import Window
import Blick.Type exposing (..)
import Blick.Constant exposing (singleColumnMaxWidthPx)
import Blick.View.Parts exposing (..)


modal : Window.Size -> MatId -> Material -> Html Msg
modal { width } ((MatId id_) as matId) material =
    div [ class "modal is-active", id <| "detail-" ++ id_ ]
        [ div [ class "modal-background", onClickNoPropagate (GoTo Root) ] []
        , div [ class "hero is-light" ]
            [ div [ class "hero-body" ]
                [ div [ class "container is-fullhd" ]
                    [ detailContents width matId material
                    ]
                ]
            ]
        , button [ class "modal-close is-large", attribute "aria-label" "close", onClickNoPropagate (GoTo Root) ] []
        ]


detailContents : Int -> MatId -> Material -> Html Msg
detailContents width ((MatId id_) as matId) { title, url, thumbnail_url, author_email } =
    div [ class <| "columns" ++ detailColumnsClass width ]
        [ div [ class "column is-two-thirds" ]
            [ a [ link url, target "_blank" ]
                [ Z.lazy detailThumbnail thumbnail_url
                ]
            ]
        , div [ class "column" ]
            [ h1 [ class "title" ] [ text title ]
            , div [ class "tags" ] [ authorTag (Selector (".modal[id='detail-" ++ id_ ++ "']")) matId author_email ]
            ]
        ]


detailColumnsClass : Int -> String
detailColumnsClass width =
    if width <= singleColumnMaxWidthPx then
        ""
    else
        " is-mobile"


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
