port module Main exposing (..)

-- import DeactivateButton

import Browser
import Browser.Hash as Hash
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onBlur, onClick, onInput)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Json.Encode.Extra as EncodeExtra
import List.Extra as ListExtra
import Modal exposing (..)
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
    , bomUuidToDelete : String
    , currentSeed : Random.Seed
    , seed : Int
    , modalContent : Html Msg
    , selectedBom : Maybe Bom
    , bomSearch : String
    }


type alias Flag =
    { seed : Int
    }


init : Flag -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( { key = key
      , url = url
      , showModal = False
      , bomUuidToDelete = ""
      , boms = Just []
      , bomItems = Just []
      , currentSeed = Random.initialSeed flags.seed
      , seed = flags.seed
      , modalContent =
            div
                []
                []
      , selectedBom = Nothing
      , bomSearch = ""
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOpStr String
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | SetModel Model
    | Recv IdbRecvModel
    | AddBom
    | ChangeBomName (Maybe String) String
    | ToggleModal
    | ShowBomUuidDeleteModal String
    | DeleteBom String
    | SearchBom String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SearchBom str ->
            ( { model | bomSearch = str }, Cmd.none )

        DeleteBom bomUuid ->
            ( { model
                | showModal = False
                , boms =
                    case model.boms of
                        Just boms ->
                            Just (List.filter (\bom -> bom.uuid /= Just bomUuid) boms)

                        Nothing ->
                            Nothing
              }
            , Cmd.none
            )

        ShowBomUuidDeleteModal bomUuid ->
            ( { model
                | showModal = True
                , bomUuidToDelete = bomUuid
                , modalContent =
                    div []
                        [ div []
                            [ div
                                [ class "text-xl font-bold mb-2" ]
                                [ text <|
                                    "Really delete BoM "
                                        ++ ((case model.boms of
                                                Just modelBoms ->
                                                    case ListExtra.find (\bom -> bom.uuid == Just bomUuid) modelBoms of
                                                        Just foundBom ->
                                                            Maybe.withDefault "" foundBom.name

                                                        _ ->
                                                            ""

                                                _ ->
                                                    ""
                                            )
                                                ++ "?"
                                           )
                                ]
                            ]
                        , hr [] []
                        , div
                            [ class "my-3" ]
                            [ text "This action cannot be undone." ]
                        , hr [] []
                        , div [ class "flex justify-end my-2" ]
                            [ div [ class "mx-2" ]
                                [ button
                                    [ class "px-2 py-1 rounded-md text-red-500"
                                    , onClick ToggleModal
                                    ]
                                    [ text "No" ]
                                ]
                            , div [ class "mx-2" ]
                                [ button
                                    [ class "px-2 py-1 bg-red-500 text-white rounded-md"
                                    , onClick <|
                                        DeleteBom
                                            bomUuid
                                    ]
                                    [ text "Yes" ]
                                ]
                            ]
                        ]
              }
            , Cmd.none
            )

        ToggleModal ->
            ( { model | showModal = not model.showModal }, Cmd.none )

        NoOpStr _ ->
            ( model, Cmd.none )

        ChangeBomName bomUuid name ->
            let
                newBoms : List Bom
                newBoms =
                    List.map
                        (\bom ->
                            if bom.uuid == bomUuid then
                                { bom | name = Just name }

                            else
                                bom
                        )
                        (Maybe.withDefault [] model.boms)
            in
            ( { model | boms = Just newBoms }
            , idbSend
                { table = "boms"
                , content = Encode.encode 0 (Encode.list bomEncoder newBoms)
                }
            )

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
            ( { model | currentSeed = newSeed }
            , case model.boms of
                Just boms ->
                    idbSend
                        { table = "boms"
                        , content = Encode.encode 0 (Encode.list bomEncoder (boms ++ [ newBom ]))
                        }

                _ ->
                    Cmd.none
            )

        Recv recvModel ->
            -- (Debug.log <| Debug.toString recvModel)
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
                    [ class "px-2 py-2 font-bold text-white bg-blue-500 hover:bg-blue-700"
                    , onClick
                        (SetModel
                            { model
                                | showModal = not model.showModal
                                , modalContent =
                                    div []
                                        [ div [] [ div [ class "text-xl font-bold mb-2" ] [ text "Really delete BoM ?" ] ]
                                        , hr [] []
                                        , div
                                            [ class "my-3" ]
                                            [ text "This action cannot be undone." ]
                                        , hr [] []
                                        , div [ class "flex justify-end my-2" ]
                                            [ div [ class "mx-2" ]
                                                [ button
                                                    [ class "px-2 py-1 rounded-md text-red-500"
                                                    , onClick ToggleModal
                                                    ]
                                                    [ text "No" ]
                                                ]
                                            , div [ class "mx-2" ]
                                                [ button
                                                    [ class "px-2 py-1 bg-red-500 text-white rounded-md"
                                                    , onClick ToggleModal
                                                    ]
                                                    [ text "Yes" ]
                                                ]
                                            ]
                                        ]
                            }
                        )
                    ]
                    [ text "Show modal" ]
                , button
                    [ class "px-2 py-2 font-bold text-white bg-green-500 hover:bg-green-700", onClick AddBom ]
                    [ text "Add BoM" ]
                , div [ class "flex my-3" ]
                    [ input
                        [ class "flex-grow border-2 border-gray-500 rounded-md px-2 py-1"
                        , placeholder "Search BoM..."
                        , onInput <| SearchBom
                        ]
                        []
                    ]
                , case model.boms of
                    Just boms ->
                        div
                            []
                            (boms
                                |> List.filter
                                    (\bom ->
                                        case bom.name of
                                            Just name ->
                                                String.contains model.bomSearch (String.toLower name)

                                            _ ->
                                                True
                                    )
                                |> List.map
                                    (\bom ->
                                        div []
                                            [ div [ class "flex my-1" ]
                                                [ input
                                                    [ onInput (ChangeBomName bom.uuid)
                                                    , value <|
                                                        case bom.name of
                                                            Just name ->
                                                                name

                                                            _ ->
                                                                ""
                                                    , class "flex-grow border-2 border-grey-500 px-2 py-1 shadow shadow-md"
                                                    , placeholder "BoM Name..."
                                                    ]
                                                    []
                                                , button
                                                    [ class "py-1 px-2 ml-2 bg-red-500 hover:bg-red-600 text-white rounded-md"
                                                    , onClick <|
                                                        ShowBomUuidDeleteModal <|
                                                            Maybe.withDefault "" bom.uuid
                                                    ]
                                                    [ i
                                                        [ class "bi bi-trash-fill" ]
                                                        []
                                                    ]
                                                ]
                                            ]
                                    )
                            )

                    _ ->
                        div [] []
                ]
            , modal model.showModal
                model.modalContent

            -- , modal model
            ]
        ]
    }


viewLink : String -> Html msg
viewLink path =
    li [] [ a [ class "text-blue-500", href path ] [ text path ] ]
