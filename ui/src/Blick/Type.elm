module Blick.Type exposing (Flags, Model, Msg(..))

import Date exposing (Date)


-- FLAGS


type alias Flags =
    {}



-- MESSAGES


type Msg
    = NoOp



-- MODEL


type alias Model =
    { materials : List Material
    }


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


type Url
    = Url String


type Email
    = Email String


type Type_
    = GgoogleSlide
    | GoogleDoc
    | GoogleFile
    | GoogleFolder
    | Qiita
    | Html_
