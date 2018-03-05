module Blick.Type
    exposing
        ( Flags
        , Model
        , Msg(..)
        , Success(..)
        , Field
        , ClickPos
        , Route(..)
        , Material
        , Url(Url)
        , Email(Email)
        , Type_(..)
        , Exception
        , materialDecoder
        , fromHttpError
        )

import Date exposing (Date)
import Time exposing (Time)
import Dict exposing (Dict)
import Json.Decode as D exposing (Decoder, Value)
import Json.Decode.Extra exposing ((|:), date)
import Http as H
import Navigation exposing (Location)
import Window


-- FLAGS


type alias Flags =
    Value



-- MESSAGES


type Msg
    = Loc Location
    | GoTo Route
    | WindowSize Window.Size
    | TimedErr H.Error Time
    | CloseErr Time
    | ClientRes (Result H.Error Success)
    | CarouselNext
    | CarouselPrev
    | TableNext
    | TablePrev
    | Filter String
    | StartEdit String Field ClickPos -- ID, Field, Coordinate of the click
    | SubmitEdit String Field -- ID, Field
    | CancelEdit


type Success
    = ListMaterials (Dict String Material)
    | GetMaterial ( String, Material )


type alias Field =
    { name_ : String
    , value_ : String
    }


type alias ClickPos =
    ( Int, Int )



-- MODEL


type alias Model =
    { materials : Dict String Material -- ID-Material Dict
    , editing : Maybe ( String, Field, ClickPos )
    , matches : List String -- List of IDs
    , filterInput : String
    , carouselPage : Int
    , tablePage : Int
    , route : Route
    , exceptions : Dict Time Exception
    , windowSize : Window.Size
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
    , public : Bool
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
        |: D.field "public" D.bool
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


type alias Exception =
    { message : String
    , description : String
    , details : List String
    }


fromHttpError : H.Error -> Exception
fromHttpError err =
    case err of
        H.BadUrl badUrl ->
            Exception "Malformed URL" badUrl []

        H.Timeout ->
            Exception "Server Timeout" "Check network connection" []

        H.NetworkError ->
            Exception "Network Error" "Check network connection" []

        H.BadStatus { url, status, headers, body } ->
            Exception (statusToString status) body (responseToList url headers body)

        H.BadPayload errStr { url, status, headers, body } ->
            Exception (statusToString status) errStr (responseToList url headers body)


statusToString : { code : Int, message : String } -> String
statusToString { code, message } =
    toString code ++ " " ++ message


responseToList : String -> Dict String String -> String -> List String
responseToList url headers body =
    [ "URL: " ++ url
    , "Headers: \n" ++ headersToString headers
    , "Body: " ++ body
    ]


headersToString : Dict String String -> String
headersToString headers =
    headers
        |> Dict.toList
        |> List.map (\( name, value ) -> name ++ " : " ++ value)
        |> String.join "\n"
