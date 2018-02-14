module Blick.Constant
    exposing
        ( singleColumnMaxWidthPx
        , mobileMaxWidthPx
        , bulmaColumnScaleMax
        , tilePerRow
        , rowPerCarouselPage
        , maxCarouselPage
        , rowPerTable
        , tablePerPage
        , maxTablePage
        )


singleColumnMaxWidthPx : Int
singleColumnMaxWidthPx =
    480


mobileMaxWidthPx : Int
mobileMaxWidthPx =
    768


bulmaColumnScaleMax : Int
bulmaColumnScaleMax =
    12


tilePerRow : Int -> Int
tilePerRow width =
    if width <= singleColumnMaxWidthPx then
        1
    else if width <= mobileMaxWidthPx then
        2
    else
        4


rowPerCarouselPage : Int
rowPerCarouselPage =
    3


maxCarouselPage : Int -> Int -> Int
maxCarouselPage width numberOfMaterials =
    numberOfMaterials // (tilePerRow width * rowPerCarouselPage)


rowPerTable : Int
rowPerTable =
    6


tablePerPage : Int
tablePerPage =
    2


maxTablePage : Int -> Int
maxTablePage numberOfMaterials =
    numberOfMaterials // (rowPerTable * tablePerPage)
