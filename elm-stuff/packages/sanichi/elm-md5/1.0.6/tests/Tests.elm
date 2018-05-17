module Tests exposing (all)

import Expect
import MD5 exposing (hex)
import Regex
import Test exposing (Test, describe)


test : String -> a -> a -> Test
test description expected actual =
    Test.test description <|
        \() ->
            Expect.equal actual expected


myHex : String -> String
myHex input =
    let
        myInput =
            Regex.replace Regex.All (Regex.regex "\x0D\n") (\_ -> "\n") input
    in
        hex myInput


all : Test
all =
    describe "hex"
        [ test "empty" "d41d8cd98f00b204e9800998ecf8427e" <| hex ""
        , test "foobar" "6df23dc03f9b54cc38a0fc1483df6e21" <| hex "foobarbaz"
        , test "lorem" "db89bb5ceab87f9c0fcc2ab36c189c2c" <| hex "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
        , test "latin1" "38e3f1e10c0b5072c874a72c3c6493d8" <| hex "æ ø å ñ"
        , test "unicode" "2adb08ac813a93665950fe9203faca10" <| hex "€ ♝ ♧ ☐"
        , test "newlines" "e1c06d85ae7b8b032bef47e42e4c08f9" <| hex "\n\n"
        , test "crlfs (replaced)" "e1c06d85ae7b8b032bef47e42e4c08f9" <| myHex "\x0D\n\x0D\n"
        ]
