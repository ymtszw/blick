module Blick.Type
    exposing
        ( Flags
        , Model
        , Msg(..)
        , Success(..)
        , Field
        , Editable
        , DirtyValue(..)
        , DOMRect
        , Selector(Selector)
        , FilterState
        , Route(..)
        , EditState
        , MatId(MatId)
        , Material
        , MaterialDict
        , Url(Url)
        , Email(Email)
        , Type_(..)
        , Exception
        , Deb(..)
        , descendantOf
        , inputId
        , dictSize
        , materialDecoder
        , matIdDecoder
        , matDictEmpty
        , matDictDecoder
        , matDictGet
        , matDictInsert
        , matDictFilter
        , matDictSplit
        , matDictUnion
        , matDictToList
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
    | PurgeErr Time
    | ClientRes (Result H.Error Success)
    | SetCarouselPage Int
    | SetTablePage Int
    | InputFilter String
    | SetFilterFocus Bool
    | FocusFilter Bool
    | DebLift Int Msg
    | DebTick Int Msg
    | DebDrop
    | InitiateEdit MatId Field Selector
    | StartEdit MatId Field DOMRect
    | InputEdit EditState Editable
    | CompleteEdit EditState Editable
    | SelectSuggestion Int
    | SubmitEdit MatId Field
    | CancelEdit


type Success
    = ListMaterials MaterialDict
    | GetMaterial ( MatId, Material )
    | UpdateMaterialField ( MatId, Material )
    | ListMembers (List Email)


type alias Field =
    { name_ : String
    , value_ : Editable
    }


type alias Editable =
    { prev : Maybe String
    , edit : DirtyValue
    }


type DirtyValue
    = UnTouched
    | ManualInput String
    | AutoCompleted String


inputId : MatId -> Field -> String
inputId (MatId id_) { name_ } =
    id_ ++ "-" ++ name_


type Selector
    = Selector String


descendantOf : Selector -> Selector -> Selector
descendantOf (Selector ancestor) (Selector target) =
    Selector (ancestor ++ " " ++ target)


type alias DOMRect =
    { left : Float
    , top : Float
    , width : Float
    , height : Float
    }



-- MODEL


type alias Model =
    { materials : MaterialDict
    , editing : Maybe EditState
    , selectedSuggestion : Maybe Int
    , matches : List MatId
    , filter : FilterState
    , members : List Email
    , carouselPage : Int
    , tablePage : Int
    , route : Route
    , exceptions : Dict Time Exception
    , windowSize : Window.Size
    , deb : Deb
    }


type Deb
    = Grounded
    | Excited Int Msg


type alias FilterState =
    { focused : Bool
    , value_ : String
    }


type Route
    = Root
    | Detail MatId
    | NotFound


type alias EditState =
    { matId : MatId
    , field : Field
    , domRect : DOMRect -- editor element's DOMRect
    }


type TaggedStringKeyDict key val
    = TaggedStringKeyDict (Dict String val)


dictSize : TaggedStringKeyDict key val -> Int
dictSize (TaggedStringKeyDict dict) =
    Dict.size dict


type alias MaterialDict =
    TaggedStringKeyDict MatId Material


matDictEmpty : MaterialDict
matDictEmpty =
    TaggedStringKeyDict Dict.empty


matDictInsert : MatId -> Material -> MaterialDict -> MaterialDict
matDictInsert (MatId id) material (TaggedStringKeyDict dict) =
    TaggedStringKeyDict (Dict.insert id material dict)


matDictGet : MatId -> MaterialDict -> Maybe Material
matDictGet (MatId id) (TaggedStringKeyDict dict) =
    Dict.get id dict


matDictFilter : (MatId -> Material -> Bool) -> MaterialDict -> MaterialDict
matDictFilter filter (TaggedStringKeyDict dict) =
    TaggedStringKeyDict (Dict.filter (\strKey material -> filter (MatId strKey) material) dict)


matDictSplit : (MatId -> Material -> Bool) -> MaterialDict -> ( MaterialDict, MaterialDict )
matDictSplit splitter (TaggedStringKeyDict dict) =
    let
        ( trues, falses ) =
            Dict.partition (\strKey material -> splitter (MatId strKey) material) dict
    in
        ( TaggedStringKeyDict trues, TaggedStringKeyDict falses )


matDictUnion : MaterialDict -> MaterialDict -> MaterialDict
matDictUnion (TaggedStringKeyDict dict1) (TaggedStringKeyDict dict2) =
    TaggedStringKeyDict (Dict.union dict1 dict2)


matDictToList : MaterialDict -> List ( MatId, Material )
matDictToList (TaggedStringKeyDict dict) =
    Dict.foldr (\idStr mat acc -> ( MatId idStr, mat ) :: acc) [] dict


type MatId
    = MatId String


matIdDecoder : Decoder MatId
matIdDecoder =
    D.map MatId D.string


matDictDecoder : Decoder MaterialDict
matDictDecoder =
    D.map TaggedStringKeyDict (D.dict (D.field "data" materialDecoder))


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
    , isOpen : Bool
    }


fromHttpError : H.Error -> Exception
fromHttpError err =
    case err of
        H.BadUrl badUrl ->
            Exception "Malformed URL" badUrl [] True

        H.Timeout ->
            Exception "Server Timeout" "Check network connection" [] True

        H.NetworkError ->
            Exception "Network Error" "Check network connection" [] True

        H.BadStatus { url, status, headers, body } ->
            Exception (statusToString status) body (responseToList url headers body) True

        H.BadPayload errStr { url, status, headers, body } ->
            Exception (statusToString status) errStr (responseToList url headers body) True


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
