module MD5 exposing (hex)

{-| This library allows you to compute MD5 message digests in Elm. It exposes a
single function that takes any string and outputs a "fingerprint" containing 32
hexadecimal characters. More information about the MD5 algorithm can be found
[here](https://en.wikipedia.org/wiki/MD5).

# Digest Functions
@docs hex

-}

import Array exposing (Array)
import Bitwise exposing (and, complement, or, shiftLeftBy, shiftRightBy, shiftRightZfBy)
import Char
import String


{-| Given a string of arbitrary length, returns a string of 32 hexadecimal characters (a-f, 0-9)
representing the 128-bit MD5 message digest.

    hex ""          == "d41d8cd98f00b204e9800998ecf8427e"
    hex "foobarbaz" == "6df23dc03f9b54cc38a0fc1483df6e21"

Unlike the [Javascript program](https://css-tricks.com/snippets/javascript/javascript-md5/) upon which this
implementation is based, CRLF pairs in the input are not automatically replaced with LFs prior to computing
the digest. If you want that behaviour you should adjust the input yourself before evaluating the function.
For example:

    myHex : String -> String
    myHex input =
        let
            myInput =
                Regex.replace Regex.All (Regex.regex "\x0D\n") (\_ -> "\n") input
        in
            hex myInput
-}
hex : String -> String
hex string =
    let
        x =
            utf8Encode string |> convertToWordArray

        ( a, b, c, d ) =
            hex_ x 0 ( 0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476 )
    in
        wordToHex a ++ wordToHex b ++ wordToHex c ++ wordToHex d


hex_ : Array Int -> Int -> ( Int, Int, Int, Int ) -> ( Int, Int, Int, Int )
hex_ x k ( a, b, c, d ) =
    if k >= Array.length x then
        ( a, b, c, d )
    else
        let
            s11 =
                7

            s12 =
                12

            s13 =
                17

            s14 =
                22

            s21 =
                5

            s22 =
                9

            s23 =
                14

            s24 =
                20

            s31 =
                4

            s32 =
                11

            s33 =
                16

            s34 =
                23

            s41 =
                6

            s42 =
                10

            s43 =
                15

            s44 =
                21

            a00 =
                a

            b00 =
                b

            c00 =
                c

            d00 =
                d

            a01 =
                ff a00 b00 c00 d00 (iget (k + 0) x) s11 0xD76AA478

            d01 =
                ff d00 a01 b00 c00 (iget (k + 1) x) s12 0xE8C7B756

            c01 =
                ff c00 d01 a01 b00 (iget (k + 2) x) s13 0x242070DB

            b01 =
                ff b00 c01 d01 a01 (iget (k + 3) x) s14 0xC1BDCEEE

            a02 =
                ff a01 b01 c01 d01 (iget (k + 4) x) s11 0xF57C0FAF

            d02 =
                ff d01 a02 b01 c01 (iget (k + 5) x) s12 0x4787C62A

            c02 =
                ff c01 d02 a02 b01 (iget (k + 6) x) s13 0xA8304613

            b02 =
                ff b01 c02 d02 a02 (iget (k + 7) x) s14 0xFD469501

            a03 =
                ff a02 b02 c02 d02 (iget (k + 8) x) s11 0x698098D8

            d03 =
                ff d02 a03 b02 c02 (iget (k + 9) x) s12 0x8B44F7AF

            c03 =
                ff c02 d03 a03 b02 (iget (k + 10) x) s13 0xFFFF5BB1

            b03 =
                ff b02 c03 d03 a03 (iget (k + 11) x) s14 0x895CD7BE

            a04 =
                ff a03 b03 c03 d03 (iget (k + 12) x) s11 0x6B901122

            d04 =
                ff d03 a04 b03 c03 (iget (k + 13) x) s12 0xFD987193

            c04 =
                ff c03 d04 a04 b03 (iget (k + 14) x) s13 0xA679438E

            b04 =
                ff b03 c04 d04 a04 (iget (k + 15) x) s14 0x49B40821

            a05 =
                gg a04 b04 c04 d04 (iget (k + 1) x) s21 0xF61E2562

            d05 =
                gg d04 a05 b04 c04 (iget (k + 6) x) s22 0xC040B340

            c05 =
                gg c04 d05 a05 b04 (iget (k + 11) x) s23 0x265E5A51

            b05 =
                gg b04 c05 d05 a05 (iget (k + 0) x) s24 0xE9B6C7AA

            a06 =
                gg a05 b05 c05 d05 (iget (k + 5) x) s21 0xD62F105D

            d06 =
                gg d05 a06 b05 c05 (iget (k + 10) x) s22 0x02441453

            c06 =
                gg c05 d06 a06 b05 (iget (k + 15) x) s23 0xD8A1E681

            b06 =
                gg b05 c06 d06 a06 (iget (k + 4) x) s24 0xE7D3FBC8

            a07 =
                gg a06 b06 c06 d06 (iget (k + 9) x) s21 0x21E1CDE6

            d07 =
                gg d06 a07 b06 c06 (iget (k + 14) x) s22 0xC33707D6

            c07 =
                gg c06 d07 a07 b06 (iget (k + 3) x) s23 0xF4D50D87

            b07 =
                gg b06 c07 d07 a07 (iget (k + 8) x) s24 0x455A14ED

            a08 =
                gg a07 b07 c07 d07 (iget (k + 13) x) s21 0xA9E3E905

            d08 =
                gg d07 a08 b07 c07 (iget (k + 2) x) s22 0xFCEFA3F8

            c08 =
                gg c07 d08 a08 b07 (iget (k + 7) x) s23 0x676F02D9

            b08 =
                gg b07 c08 d08 a08 (iget (k + 12) x) s24 0x8D2A4C8A

            a09 =
                hh a08 b08 c08 d08 (iget (k + 5) x) s31 0xFFFA3942

            d09 =
                hh d08 a09 b08 c08 (iget (k + 8) x) s32 0x8771F681

            c09 =
                hh c08 d09 a09 b08 (iget (k + 11) x) s33 0x6D9D6122

            b09 =
                hh b08 c09 d09 a09 (iget (k + 14) x) s34 0xFDE5380C

            a10 =
                hh a09 b09 c09 d09 (iget (k + 1) x) s31 0xA4BEEA44

            d10 =
                hh d09 a10 b09 c09 (iget (k + 4) x) s32 0x4BDECFA9

            c10 =
                hh c09 d10 a10 b09 (iget (k + 7) x) s33 0xF6BB4B60

            b10 =
                hh b09 c10 d10 a10 (iget (k + 10) x) s34 0xBEBFBC70

            a11 =
                hh a10 b10 c10 d10 (iget (k + 13) x) s31 0x289B7EC6

            d11 =
                hh d10 a11 b10 c10 (iget (k + 0) x) s32 0xEAA127FA

            c11 =
                hh c10 d11 a11 b10 (iget (k + 3) x) s33 0xD4EF3085

            b11 =
                hh b10 c11 d11 a11 (iget (k + 6) x) s34 0x04881D05

            a12 =
                hh a11 b11 c11 d11 (iget (k + 9) x) s31 0xD9D4D039

            d12 =
                hh d11 a12 b11 c11 (iget (k + 12) x) s32 0xE6DB99E5

            c12 =
                hh c11 d12 a12 b11 (iget (k + 15) x) s33 0x1FA27CF8

            b12 =
                hh b11 c12 d12 a12 (iget (k + 2) x) s34 0xC4AC5665

            a13 =
                ii a12 b12 c12 d12 (iget (k + 0) x) s41 0xF4292244

            d13 =
                ii d12 a13 b12 c12 (iget (k + 7) x) s42 0x432AFF97

            c13 =
                ii c12 d13 a13 b12 (iget (k + 14) x) s43 0xAB9423A7

            b13 =
                ii b12 c13 d13 a13 (iget (k + 5) x) s44 0xFC93A039

            a14 =
                ii a13 b13 c13 d13 (iget (k + 12) x) s41 0x655B59C3

            d14 =
                ii d13 a14 b13 c13 (iget (k + 3) x) s42 0x8F0CCC92

            c14 =
                ii c13 d14 a14 b13 (iget (k + 10) x) s43 0xFFEFF47D

            b14 =
                ii b13 c14 d14 a14 (iget (k + 1) x) s44 0x85845DD1

            a15 =
                ii a14 b14 c14 d14 (iget (k + 8) x) s41 0x6FA87E4F

            d15 =
                ii d14 a15 b14 c14 (iget (k + 15) x) s42 0xFE2CE6E0

            c15 =
                ii c14 d15 a15 b14 (iget (k + 6) x) s43 0xA3014314

            b15 =
                ii b14 c15 d15 a15 (iget (k + 13) x) s44 0x4E0811A1

            a16 =
                ii a15 b15 c15 d15 (iget (k + 4) x) s41 0xF7537E82

            d16 =
                ii d15 a16 b15 c15 (iget (k + 11) x) s42 0xBD3AF235

            c16 =
                ii c15 d16 a16 b15 (iget (k + 2) x) s43 0x2AD7D2BB

            b16 =
                ii b15 c16 d16 a16 (iget (k + 9) x) s44 0xEB86D391

            a17 =
                addUnsigned a00 a16

            b17 =
                addUnsigned b00 b16

            c17 =
                addUnsigned c00 c16

            d17 =
                addUnsigned d00 d16
        in
            hex_ x (k + 16) ( a17, b17, c17, d17 )


convertToWordArray : String -> Array Int
convertToWordArray input =
    let
        messageLength =
            String.length input

        tmp1 =
            messageLength + 8

        tmp2 =
            (tmp1 - (tmp1 % 64)) // 64

        numberOfWords =
            16 * (tmp2 + 1)

        words =
            Array.repeat numberOfWords 0
    in
        convertToWordArray_ input 0 messageLength words


convertToWordArray_ : String -> Int -> Int -> Array Int -> Array Int
convertToWordArray_ input byteCount messageLength words =
    let
        wordCount =
            (byteCount - (byteCount % 4)) // 4

        bytePosition =
            8 * (byteCount % 4)

        oldWord =
            iget wordCount words
    in
        if byteCount < messageLength then
            let
                str =
                    String.slice byteCount (byteCount + 1) input

                split =
                    String.uncons str

                code =
                    case split of
                        Nothing ->
                            0

                        Just ( c, _ ) ->
                            Char.toCode c |> shiftLeftBy bytePosition

                newWord =
                    or oldWord code

                newWords =
                    Array.set wordCount newWord words
            in
                convertToWordArray_ input (byteCount + 1) messageLength newWords
        else
            let
                numberOfWords =
                    Array.length words

                code =
                    shiftLeftBy bytePosition 0x80

                newWord =
                    or oldWord code

                tmp1 =
                    Array.set wordCount newWord words

                tmp2 =
                    Array.set (numberOfWords - 2) (shiftLeftBy 3 messageLength) tmp1
            in
                Array.set (numberOfWords - 1) (shiftRightZfBy 29 messageLength) tmp2


utf8Encode : String -> String
utf8Encode string =
    utf8Encode_ string ""


utf8Encode_ : String -> String -> String
utf8Encode_ input output =
    let
        split =
            String.uncons input
    in
        case split of
            Nothing ->
                output

            Just ( nextChar, remainingInput ) ->
                let
                    c =
                        Char.toCode nextChar

                    newOutput =
                        if c < 128 then
                            output ++ String.fromChar nextChar
                        else if c < 2048 then
                            output ++ (or (shiftRightBy 6 c) 192 |> Char.fromCode |> String.fromChar) ++ (or (and c 63) 128 |> Char.fromCode |> String.fromChar)
                        else
                            output ++ (or (shiftRightBy 12 c) 224 |> Char.fromCode |> String.fromChar) ++ (or (and (shiftRightBy 6 c) 63) 128 |> Char.fromCode |> String.fromChar) ++ (or (and c 63) 128 |> Char.fromCode |> String.fromChar)
                in
                    utf8Encode_ remainingInput newOutput


wordToHex : Int -> String
wordToHex input =
    wordToHex_ input 0 ""


wordToHex_ : Int -> Int -> String -> String
wordToHex_ input index output =
    if index > 3 then
        output
    else
        let
            byte =
                and (shiftRightZfBy (index * 8) input) 255

            tmp2 =
                toHex byte

            tmp1 =
                if String.length tmp2 == 1 then
                    "0"
                else
                    ""
        in
            wordToHex_ input (index + 1) (output ++ tmp1 ++ tmp2)


hexFromInt : Int -> Char
hexFromInt i =
    if i < 10 then
        Char.fromCode <| i + Char.toCode '0'
    else
        Char.fromCode <| i - 10 + Char.toCode 'a'


toHex : Int -> String
toHex i =
    if i < 16 then
        String.fromChar <| hexFromInt i
    else
        toHex (i // 16) ++ (String.fromChar <| hexFromInt (i % 16))


rotateLeft : Int -> Int -> Int
rotateLeft input bits =
    or (shiftLeftBy bits input) (shiftRightZfBy (32 - bits) input)


addUnsigned : Int -> Int -> Int
addUnsigned x y =
    let
        x8 =
            and x 0x80000000

        y8 =
            and y 0x80000000

        x4 =
            and x 0x40000000

        y4 =
            and y 0x40000000

        result =
            and x 0x3FFFFFFF + and y 0x3FFFFFFF
    in
        if and x4 y4 > 0 then
            ixor result 0x80000000 |> ixor x8 |> ixor y8
        else if or x4 y4 > 0 then
            if and result 0x40000000 > 0 then
                ixor result 0xC0000000 |> ixor x8 |> ixor y8
            else
                ixor result 0x40000000 |> ixor x8 |> ixor y8
        else
            ixor result x8 |> ixor y8


ixor : Int -> Int -> Int
ixor x y =
    Bitwise.xor x y


iget : Int -> Array Int -> Int
iget index array =
    Array.get index array |> Maybe.withDefault 0


f : Int -> Int -> Int -> Int
f x y z =
    or (and x y) (and (complement x) z)


g : Int -> Int -> Int -> Int
g x y z =
    or (and x z) (and y (complement z))


h : Int -> Int -> Int -> Int
h x y z =
    ixor x y |> ixor z


i : Int -> Int -> Int -> Int
i x y z =
    ixor y (or x (complement z))


ff : Int -> Int -> Int -> Int -> Int -> Int -> Int -> Int
ff a b c d x s ac =
    let
        z =
            addUnsigned a (addUnsigned (addUnsigned (f b c d) x) ac)
    in
        addUnsigned (rotateLeft z s) b


gg : Int -> Int -> Int -> Int -> Int -> Int -> Int -> Int
gg a b c d x s ac =
    let
        z =
            addUnsigned a (addUnsigned (addUnsigned (g b c d) x) ac)
    in
        addUnsigned (rotateLeft z s) b


hh : Int -> Int -> Int -> Int -> Int -> Int -> Int -> Int
hh a b c d x s ac =
    let
        z =
            addUnsigned a (addUnsigned (addUnsigned (h b c d) x) ac)
    in
        addUnsigned (rotateLeft z s) b


ii : Int -> Int -> Int -> Int -> Int -> Int -> Int -> Int
ii a b c d x s ac =
    let
        z =
            addUnsigned a (addUnsigned (addUnsigned (i b c d) x) ac)
    in
        addUnsigned (rotateLeft z s) b
