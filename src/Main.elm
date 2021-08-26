port module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode exposing (Decoder, int, string)
import Json.Decode.Pipeline as Pipeline exposing (optional, required)



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- PORTS


type alias RecvModel =
    { name : Maybe String, content : Maybe String }


port idbGet : String -> Cmd msg


port idbRecv : (RecvModel -> msg) -> Sub msg



-- MODEL


type alias Bom =
    {}


type alias Item =
    {}


type alias Model =
    { draft : String
    , messages : List String
    , boms : List Bom
    , items : List Item
    }


init : () -> ( Model, Cmd Msg )
init flags =
    ( { draft = "", messages = [], boms = [], items = [] }
    , Cmd.none
    )



-- UPDATE


type Msg
    = DraftChanged String
      -- | Send
    | IdbGet String
    | Recv RecvModel



-- Use the `sendMessage` port when someone presses ENTER or clicks
-- the "Send" button. Check out index.html to see the corresponding
-- JS where this is piped into a WebSocket.
--


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DraftChanged draft ->
            ( { model | draft = draft }
            , Cmd.none
            )

        IdbGet table ->
            ( model, idbGet table )

        Recv m ->
            (Debug.log <| "Helo" ++ Debug.toString m)
                ( model
                , Cmd.none
                )



-- SUBSCRIPTIONS
-- Subscribe to the `messageReceiver` port to hear about messages coming in
-- from JS. Check out the index.html file to see how this is hooked up to a
-- WebSocket.
--


subscriptions : Model -> Sub Msg
subscriptions model =
    idbRecv Recv



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "container mx-auto m-2" ]
        [ div
            [ class "flex justify-center" ]
            [ div
                [ class "p-2 font-bold text-xl border-4 border-green-700 bg-green-400 rounded-md text-gray-800" ]
                [ text "Summer" ]
            ]
        , div [ class "my-2 flex justify-center" ]
            [ div
                [ class "italic" ]
                [ text "Your Simple BoM Manager" ]
            ]
        ]



-- DETECT ENTER
