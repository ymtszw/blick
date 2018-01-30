module Blick.Type
    exposing
        ( Flags
        , Model
        , Msg(..)
        , Id(Id)
        , Material
        , Url(Url)
        , Email(Email)
        , Type_(..)
        , idDecoder
        , materialDecoder
        )

import Date exposing (Date)
import Regex
import Json.Decode as D exposing (Decoder)
import Json.Decode.Extra exposing ((|:), date)
import Json.Encode as E exposing (Value)
import Http as H
import String.Extra exposing (underscored)


-- FLAGS


type alias Flags =
    {}



-- MESSAGES


type Msg
    = ListMaterials (Result H.Error (List ( Id, Material )))
    | CarouselNext
    | CarouselPrev



-- MODEL


type alias Model =
    { materials : List ( Id, Material )
    , carouselPage : Int
    }


type Id
    = Id String


idDecoder : Decoder Id
idDecoder =
    D.map Id D.string


type alias Material =
    { title : String
    , url : Url
    , thumbnail_url : Maybe Url
    , created_time : Maybe Date
    , author_email : Maybe Email
    , type_ : Type_
    , excluded : Bool
    , exclude_reason : Maybe String
    }


materialDecoder : Decoder Material
materialDecoder =
    D.succeed Material
        |: D.field "title" D.string
        |: D.field "url" urlDecoder
        |: D.field "thumbnail_url" (D.maybe urlDecoder)
        |: D.field "created_time" (D.maybe date)
        |: D.field "author_email" (D.maybe emailDecoder)
        |: D.field "type" typeDecoder
        |: D.field "excluded" D.bool
        |: D.field "exclude_reason" (D.maybe D.string)


type Url
    = Url String


urlDecoder : Decoder Url
urlDecoder =
    D.map Url D.string


urlEncoder : Url -> Value
urlEncoder (Url url) =
    E.string url


type Email
    = Email String


emailDecoder : Decoder Email
emailDecoder =
    D.map Email D.string


emailEncoder : Email -> Value
emailEncoder (Email email) =
    E.string email


type Type_
    = GoogleSlide
    | GoogleDoc
    | GoogleFile
    | GoogleFolder
    | Qiita
    | Html_


typeDecoder : Decoder Type_
typeDecoder =
    D.map typeFromString D.string


typeFromString : String -> Type_
typeFromString str =
    case str of
        "google_slide" ->
            GoogleSlide

        "google_doc" ->
            GoogleDoc

        "google_file" ->
            GoogleFile

        "google_folder" ->
            GoogleFolder

        "qiita" ->
            Qiita

        "html" ->
            Html_

        _ ->
            Debug.crash "Unexpected type from server!!"


typeEncoder : Type_ -> Value
typeEncoder type_ =
    type_
        |> toString
        |> underscored
        |> Regex.replace (Regex.AtMost 1) (Regex.regex "_$") (always "")
        |> E.string
