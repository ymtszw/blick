module Blick.Type
    exposing
        ( Flags
        , Model
        , Msg(..)
        , Success(..)
        , Route(..)
        , Material
        , Url(Url)
        , Email(Email)
        , Type_(..)
        , materialDecoder
        )

import Date exposing (Date)
import Dict exposing (Dict)
import Json.Decode as D exposing (Decoder, Value)
import Json.Decode.Extra exposing ((|:), date)
import Http as H
import Navigation exposing (Location)


-- FLAGS


type alias Flags =
    Value



-- MESSAGES


type Msg
    = Loc Location
    | GoTo String
    | ClientRes (Result H.Error Success)
    | CarouselNext
    | CarouselPrev
    | TableNext
    | TablePrev
    | Filter String


type Success
    = ListMaterials (Dict String Material)
    | GetMaterial ( String, Material )



-- MODEL


type alias Model =
    { materials : Dict String Material
    , matches : List String
    , filterInput : String
    , carouselPage : Int
    , tablePage : Int
    , route : Route
    }


type Route
    = Root
    | Detail String
    | NotFound


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


type Email
    = Email String


emailDecoder : Decoder Email
emailDecoder =
    D.map Email D.string


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

        _ ->
            Html_
