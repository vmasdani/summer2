port module Main exposing (..)

import Browser
import Browser.Hash as Hash
import Browser.Navigation as Nav
import DeactivateButton
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Json.Encode.Extra as EncodeExtra
import Random
import Url
import Uuid


type alias IdbRecvModel =
    { table : String
    , content : String
    }


port idbRecv : (IdbRecvModel -> msg) -> Sub msg


port idbSend : IdbRecvModel -> Cmd msg


type alias Bom =
    { uuid : Maybe String, name : Maybe String }


defaultBom : Bom
defaultBom =
    { uuid = Nothing, name = Just "" }


bomDecoder : Decode.Decoder Bom
bomDecoder =
    Decode.succeed Bom
        |> Pipeline.required "uuid" (Decode.maybe Decode.string)
        |> Pipeline.required "name" (Decode.maybe Decode.string)


bomEncoder : Bom -> Encode.Value
bomEncoder bom =
    Encode.object
        [ ( "uuid", EncodeExtra.maybe Encode.string bom.uuid )
        , ( "name", EncodeExtra.maybe Encode.string bom.name )
        ]


type alias BomItem =
    { uuid : Maybe String, name : Maybe String, bomUuid : Maybe String, price : Maybe Float, url : Maybe String }


defaultBomItem : BomItem
defaultBomItem =
    { uuid = Nothing, name = Just "", bomUuid = Nothing, price = Just 0, url = Just "" }


bomItemDecoder : Decode.Decoder BomItem
bomItemDecoder =
    Decode.succeed BomItem
        |> Pipeline.required "uuid" (Decode.maybe Decode.string)
        |> Pipeline.required "name" (Decode.maybe Decode.string)
        |> Pipeline.required "bomUuid" (Decode.maybe Decode.string)
        |> Pipeline.required "price" (Decode.maybe Decode.float)
        |> Pipeline.required "url" (Decode.maybe Decode.string)



-- MAIN


main : Program Flag Model Msg
main =
    Hash.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- MODEL


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , showModal : Bool
    , boms : Maybe (List Bom)
    , bomItems : Maybe (List BomItem)
    , currentSeed : Random.Seed
    , seed : Int
    }


type alias Flag =
    { seed : Int
    }


init : Flag -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( { key = key
      , url = url
      , showModal = False
      , boms = Just []
      , bomItems = Just []
      , currentSeed = Random.initialSeed flags.seed
      , seed = flags.seed
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | SetModel Model
    | Recv IdbRecvModel
    | AddBom


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AddBom ->
            let
                ( newUuid, newSeed ) =
                    Random.step Uuid.uuidGenerator model.currentSeed

                newBom : Bom
                newBom =
                    { uuid = Just (Uuid.toString newUuid)
                    , name = Just ""
                    }
            in
            ( { model | currentSeed = newSeed }, idbSend { table = "boms", content = Encode.encode 0 (bomEncoder newBom) } )

        Recv recvModel ->
            (Debug.log <| Debug.toString recvModel)
                ( case recvModel.table of
                    "boms" ->
                        { model
                            | boms =
                                case Decode.decodeString (Decode.list bomDecoder) recvModel.content of
                                    Ok boms ->
                                        Just boms

                                    Err _ ->
                                        model.boms
                        }

                    _ ->
                        model
                , Cmd.none
                )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        SetModel newModel ->
            ( newModel, Cmd.none )

        UrlChanged url ->
            ( { model | url = url }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ idbRecv Recv
        ]



-- VIEW
-- modal : Model -> Html (Attribute Msg)


modal model =
    div
        [ class
            ("fixed z-10 inset-0 overflow-y-auto "
                ++ (if model.showModal then
                        "visible"

                    else
                        "invisible"
                   )
            )
        , attribute "aria-labelledby" "modal-title"
        , attribute "role" "dialog"
        , attribute "aria-modal" "true"
        ]
        [ div
            [ class "flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0"
            ]
            [ {-
                 Background overlay, show/hide based on modal state.

                 Entering: "ease-out duration-300"
                   From: "opacity-0"
                   To: "opacity-100"
                 Leaving: "ease-in duration-200"
                   From: "opacity-100"
                   To: "opacity-0"
              -}
              div
                [ class "fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
                , attribute "aria-hidden" "true"
                ]
                []
            , {- This element is to trick the browser into centering the modal contents. -}
              span
                [ class "hidden sm:inline-block sm:align-middle sm:h-screen"
                , attribute "aria-hidden" "true"
                ]
                [ text "\u{200B}" ]
            , {-
                 Modal panel, show/hide based on modal state.

                 Entering: "ease-out duration-300"
                   From: "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
                   To: "opacity-100 translate-y-0 sm:scale-100"
                 Leaving: "ease-in duration-200"
                   From: "opacity-100 translate-y-0 sm:scale-100"
                   To: "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
              -}
              div
                [ class "inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full"
                ]
                [ div
                    [ class "bg-white px-4 pt-5 pb-4 sm:p-6 sm:pb-4"
                    ]
                    [ div
                        [ class "sm:flex sm:items-start"
                        ]
                        [ div
                            [ class "mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-red-100 sm:mx-0 sm:h-10 sm:w-10"
                            ]
                            [{- Heroicon name: outline/exclamation -}
                             --   svg
                             --     [ Svgclass "h-6 w-6 text-red-600"
                             --     , SvgAttr.fill "none"
                             --     , SvgAttr.viewBox "0 0 24 24"
                             --     , SvgAttr.stroke "currentColor"
                             --     , attribute "aria-hidden" "true"
                             --     ]
                             --     [ path
                             --         [ SvgAttr.strokeLinecap "round"
                             --         , SvgAttr.strokeLinejoin "round"
                             --         , SvgAttr.strokeWidth "2"
                             --         , SvgAttr.d "M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                             --         ]
                             --         []
                             --     ]
                            ]
                        , div
                            [ class "mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left"
                            ]
                            [ h3
                                [ class "text-lg leading-6 font-medium text-gray-900"
                                , id "modal-title"
                                ]
                                [ text "Deactivate account" ]
                            , div
                                [ class "mt-2"
                                ]
                                [ p
                                    [ class "text-sm text-gray-500"
                                    ]
                                    [ text "Are you sure you want to deactivate your account? All of your data will be permanently removed. This action cannot be undone." ]
                                ]
                            ]
                        ]
                    ]
                , div
                    [ class "bg-gray-50 px-4 py-3 sm:px-6 sm:flex sm:flex-row-reverse"
                    ]
                    [ DeactivateButton.btn
                        (SetModel { model | showModal = not model.showModal })
                    , button
                        [ type_ "button"
                        , class "mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm"
                        ]
                        [ text "Cancel" ]
                    ]
                ]
            ]
        ]


view : Model -> Browser.Document Msg
view model =
    { title = "URL Interceptor"
    , body =
        [ div [ class "container mx-auto my-3" ]
            [ div
                [ class "flex justify-center" ]
                [ div
                    [ class "border-4 border-green-800 bg-green-600 font-bold text-white text-xl rounded-lg shadow shadow-lg p-4" ]
                    [ text "Summer" ]
                ]
            , div
                [ class "flex justify-center my-2" ]
                [ div
                    [ class "italic" ]
                    [ text "Your simple BoM List Manager" ]
                ]
            , hr [ class "my-2 border-2 border-gray-400" ] []
            , div [ class "m-3" ]
                [ div [] [ text <| String.fromInt model.seed ]
                , div []
                    [ text <| Debug.toString (Random.step Uuid.uuidGenerator model.currentSeed)
                    ]
                    
                , button
                    [ class "px-2 py-2 font-bold text-white bg-blue-500 hover:bg-blue-700", onClick (SetModel { model | showModal = not model.showModal }) ]
                    [ text "Show modal" ]
                , button
                    [ class "px-2 py-2 font-bold text-white bg-green-500 hover:bg-green-700", onClick AddBom ]
                    [ text "Add BoM" ]
                , case model.boms of
                    Just boms ->
                        div
                            []
                            (List.map
                                (\bom ->
                                    div []
                                        [ div []
                                            [ text <|
                                                case bom.uuid of
                                                    Just uuid ->
                                                        uuid

                                                    _ ->
                                                        ""
                                            ]
                                        ]
                                )
                                boms
                            )

                    _ ->
                        div [] []
                ]
            , modal model
            ]
        ]
    }


viewLink : String -> Html msg
viewLink path =
    li [] [ a [ class "text-blue-500", href path ] [ text path ] ]
