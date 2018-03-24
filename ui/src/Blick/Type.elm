module Blick.Type
    exposing
        ( Flags
        , Model
        , Msg(..)
        , Success(..)
        , Field
        , DOMRect
        , Selector
        , Route(..)
        , EditState
        , Material
        , Url
        , Email(Email)
        , Type_(..)
        , Exception
        , rawStr
        , selector
        , descendantOf
        , inputId
        , materialDecoder
        , emailDecoder
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
    | NoOp
    | WindowSize Window.Size
    | TimedErr H.Error Time
    | CloseErr Time
    | ClientRes (Result H.Error Success)
    | CarouselNext
    | CarouselPrev
    | TableNext
    | TablePrev
    | Filter String
    | InitiateEdit String Field Selector
    | StartEdit EditState
    | SubmitEdit String Field
    | CancelEdit


type Success
    = ListMaterials (Dict String Material)
    | GetMaterial ( String, Material )
    | UpdateMaterialField ( String, Material )
    | ListMembers (List Email)


type alias Field =
    { name_ : String
    , value_ : String
    }


inputId : String -> Field -> String
inputId id_ { name_ } =
    id_ ++ "-" ++ name_


{-| Tagged String [Phantom Type]
-}
type TaggedString tag
    = S String


rawStr : TaggedString tag -> String
rawStr (S str) =
    str


type SelectorTag
    = SelectorTag


type alias Selector =
    TaggedString SelectorTag


selector : String -> Selector
selector str =
    S str


descendantOf : Selector -> Selector -> Selector
descendantOf (S ancestor) (S target) =
    S (ancestor ++ " " ++ target)


type alias DOMRect =
    { left : Float
    , top : Float
    , width : Float
    , height : Float
    }



-- MODEL


type alias Model =
    { materials : Dict String Material -- ID-Material Dict
    , toEdit : Maybe ( String, Field )
    , editing : Maybe EditState
    , matches : List String -- List of IDs
    , filterInput : String
    , members : List Email
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


type alias EditState =
    ( String -- editor element's id
    , Field -- editing field
    , DOMRect -- editor element's DOMRect
    )


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


type alias Url =
    TaggedString UrlTag


type UrlTag
    = UrlTag


url : String -> Url
url str =
    S str


urlDecoder : Decoder Url
urlDecoder =
    D.map url D.string


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
