module Blick.Constant exposing (..)


bulmaColumnScaleMax : Int
bulmaColumnScaleMax =
    12


tilePerRow : Int
tilePerRow =
    4


rowPerCarouselPage : Int
rowPerCarouselPage =
    3


maxCarouselPage : Int -> Int
maxCarouselPage numberOfMaterials =
    numberOfMaterials // (tilePerRow * rowPerCarouselPage)


rowPerTable : Int
rowPerTable =
    6


tablePerPage : Int
tablePerPage =
    2


maxTablePage : Int -> Int
maxTablePage numberOfMaterials =
    numberOfMaterials // (rowPerTable * tablePerPage)
