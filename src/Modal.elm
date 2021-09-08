module Modal exposing (..)

import Html exposing (..)
import Html.Attributes as Attr exposing (..)


modal : Bool -> Html msg -> Html msg
modal show content =
    {- This example requires Tailwind CSS v2.0+ -}
    div
        [ class <|
            (if show then
                "visible"

             else
                "invisible"
            )
                ++ " fixed z-10 inset-0 overflow-y-auto"
        , Attr.attribute "aria-labelledby" "modal-title"
        , Attr.attribute "role" "dialog"
        , Attr.attribute "aria-modal" "true"
        ]
        [ div
            [ Attr.class "flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0"
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
                [ Attr.class <|
                    (if show then
                        "visible"

                     else
                        "invisible"
                    )
                        ++ " fixed inset-0 bg-gray-500 bg-opacity-75 "
                , Attr.attribute "aria-hidden" "true"
                ]
                []
            , {- This element is to trick the browser into centering the modal contents. -}
              span
                [ Attr.class "hidden sm:inline-block sm:align-middle sm:h-screen"
                , Attr.attribute "aria-hidden" "true"
                ]
                [ text "\u{200B}" ]
            , div
                [ Attr.class <|
                    (if show then
                        "visible"

                     else
                        "invisible"
                    )
                        ++ " inline-block align-bottom bg-white rounded-lg text-left overflow-hidden shadow-xl transform sm:my-8 sm:align-middle sm:max-w-lg sm:w-full"
                ]
                [ div [ class "p-3" ] [ content ]
                ]
            ]
        ]
