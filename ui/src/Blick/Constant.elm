module Blick.Constant exposing (..)


bulmaColumnScaleMax : Int
bulmaColumnScaleMax =
    12


tilePerRow : Int
tilePerRow =
    4


rowPerPage : Int
rowPerPage =
    3


maxCarouselPage : Int -> Int
maxCarouselPage numberOfMaterials =
    numberOfMaterials // (tilePerRow * rowPerPage)
