module Page.Papers exposing (..)

import List.Extra exposing (find)
import DataSource exposing (DataSource)
import Head
import Head.Seo as Seo
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Shared
import View exposing (View)
import DataSource.File
import OptimizedDecoder as Decode exposing (Decoder)

import List.Extra
import String

import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Alert as Alert
import Bootstrap.Button as Button
import Bootstrap.CDN as CDN
import Bootstrap.Form as Form
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Form.Textarea as Textarea
import Bootstrap.Popover as Popover
import Bootstrap.Text as Text
import Bootstrap.Table as Table
import Bootstrap.Spinner as Spinner

import Browser
import Browser.Navigation as Nav

import Html
import Html.Attributes as HtmlAttr
import Html.Attributes exposing (class, for, href, placeholder)
import Html.Events exposing (..)
import List.Extra exposing (find)
import DataSource exposing (DataSource)
import Head
import Head.Seo as Seo
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import View exposing (View)
import DataSource.File
import OptimizedDecoder as Decode exposing (Decoder)

import Shared
import Lab.Lab as Lab
import Lab.BDBLab as BDBLab

type alias Data = (List Lab.Publication, List Lab.Member)
type alias RouteParams = {}

type alias Model =
    { activeYear : Maybe Int
    }

type Msg =
    NoOp
    | ActivateYear Int
    | DeactivateYear

head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "elm-pages"
        , image =
            { url = Pages.Url.external "TODO"
            , alt = "elm-pages logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "TODO"
        , locale = Nothing
        , title = "TODO title" -- metadata.title -- TODO
        }
        |> Seo.website


page = Page.prerender
        { head = head
        , routes = DataSource.succeed [{}]
        , data = \_ -> DataSource.map2 (\a b -> (a,b)) BDBLab.papers BDBLab.members
        }
        |> Page.buildWithLocalState
            { view = view
            , init = \_ _ staticPayload -> init ()
            , update = \_ _ _ _ -> update
            , subscriptions = \_ _ _ _-> Sub.none
            }

init : () -> ( Model, Cmd Msg )
init () =
    ( { activeYear = Nothing
      }
    , Cmd.none
    )

-- UPDATE

years : List Lab.Publication -> List Int
years papers = papers
            |> List.map (\p -> p.year)
            |> List.sort
            |> List.Extra.unique

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model = case msg of
    DeactivateYear -> ( {activeYear = Nothing } , Cmd.none )
    ActivateYear y -> ( {activeYear = Just y } , Cmd.none )
    NoOp -> ( model , Cmd.none )

view :
    Maybe PageUrl
    -> Shared.Model
    -> Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel model static =
    { title = "BDB-Lab Papers"
    , body =
        [Grid.simpleRow
            [showPapers static.data model
            ,showSelection static.data model
            ]]
    }


intro = Html.p [] [Html.text """
This lists the publications from the group
"""]

outro = Html.p [] []

showSelection (papers, _) model =
    Grid.col [Col.xs4]
        [Html.div
            [HtmlAttr.style "margin-top" "10em"
            ,HtmlAttr.style "padding-left" "2em"
            ,HtmlAttr.style "border-left" "2px black solid"
            ]
            ([Html.h3 [] [Html.text "Filters"]
            ,Html.h4 [] [Html.text "Year of publication"]
            ] ++ (years papers |> List.map (\y ->
                let
                    (action, pre) =if Just y == model.activeYear
                            then (DeactivateYear, "* ")
                            else (ActivateYear y, "")
                in (Html.p []
                    [Html.a [onClick action, href "#"] [Html.text (pre ++ String.fromInt y)]
                    ]))))]

showPapers : (List Lab.Publication, List Lab.Member) -> Model -> Grid.Column Msg
showPapers (papers, members) model =
    let apapers = case model.activeYear of
            Nothing -> papers
            Just y -> List.filter (\p -> p.year == y) papers
    in Grid.col []
        ([Html.h3 [] [Html.text "Publications"]
        ] ++ List.indexedMap (showPaper members) apapers)

showPaper members ix p =
    Grid.simpleRow [Grid.col
        []
        [Html.h4 [HtmlAttr.style "padding-top" "2em"]
            [Html.text (String.fromInt (1+ix) ++ ". ")
            ,Html.cite [] [Html.text p.title]]
        ,Grid.simpleRow
            [Grid.col []
                [Html.img [HtmlAttr.src ("/images/papers/"++p.slug++".png")
                ,HtmlAttr.style "max-width" "320px"
                ,HtmlAttr.style "max-height" "320px"
                ,HtmlAttr.style "border-radius" "20%"
                ] []]
            ,Grid.col []
                [Html.p []
                    ([Html.text "by "
                    ] ++ showAuthors p.authors members)
                ,Html.p [] [Html.text p.short_description]
                ]
            ]
        ]]

showAuthors ax members = List.intersperse (Html.text ", ") (List.map
        (\a -> case findMember a members of
                Just ba -> Html.a [HtmlAttr.href ("/person/"++ba.slug)] [Html.text a]
                Nothing -> Html.text a)
        ax)

findMember a = find (\m -> m.name == a)