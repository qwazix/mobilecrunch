import QtQuick 1.1

Rectangle {
    width: appWindow.width
    height: appWindow.height
    color: "transparent"
    Column {
        anchors.fill: parent
        Rectangle{
            height: 90
            width: parent.width
            color: "transparent"
            TitleText{
                text: "settings + tips"
            }
        }
        ButtonRow{
            anchors.horizontalCenter: parent.horizontalCenter
            Button{
//                        platformStyle : ButtonStyle {
//                                    checkedBackground: "image://theme/" + "color19-" + "meegotouch-button"+__invertedString+"-background-selected-horizontal-left"
//                                    pressedBackground: "image://theme/" + "color19-" + "meegotouch-button"+__invertedString+"-background-pressed-horizontal-left"
//                                }

                text: "degrees"
                onClicked: {
                    mn.setAngleModeDegree()
                    result.text= mn.autoCalc(tf.text)
                    console.log(mn.getAngleMode()=='d')
                }
                checked: {return (mn.getAngleMode() == 'd')}
            }
            Button{
//                        platformStyle : ButtonStyle {
//                                    checkedBackground: "image://theme/" + "color19-" + "meegotouch-button"+__invertedString+"-background-selected-horizontal-right"
//                                    pressedBackground: "image://theme/" + "color19-" + "meegotouch-button"+__invertedString+"-background-pressed-horizontal-right"
//                                }
                text: "radians"
                onClicked: {
                    mn.setAngleModeRadian()
                    result.text= mn.autoCalc(tf.text)
                }
                checked: {return (mn.getAngleMode() == 'r')}
            }
        }
        Rectangle{
            color: "transparent"
            height: 40
            width: parent.width
        }

        Text{
            text: "Tips:"
            color: "white"
            width: parent.width - 60
            font.pixelSize: 60
            anchors.left: parent.left;
            anchors.leftMargin: 30
        }
        Text{
            text: "Double tap on any function in the functions page to insert it to the running expression."
            color: "white"
            width: parent.width - 90
            font.pixelSize: 40
            wrapMode: "WordWrap"
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Rectangle{
            color: "transparent"
            height: 20
            width: parent.width
        }
        Text{
            text: "Tap in the expression box to bring up the native virtual keyboard, so you can type complex expressions."
            color: "white"
            width: parent.width - 90
            font.pixelSize: 40
            wrapMode: "WordWrap"
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Rectangle{
            color: "transparent"
            height: 20
            width: parent.width
        }
        Text{
            text: "Tap on any result on the till to insert it to the running expression."
            color: "white"
            width: parent.width - 90
            font.pixelSize: 40
            wrapMode: "WordWrap"
            anchors.horizontalCenter: parent.horizontalCenter
        }

    }
}
