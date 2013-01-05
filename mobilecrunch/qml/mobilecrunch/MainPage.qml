import QtQuick 1.1
import QtQuick 1.0

Image {
    source: "background.png"
    fillMode: Image.Tile
    anchors.fill: parent;
    Rectangle{
        color: Qt.rgba(0,0,0,0.3);
        width: parent.width
        height: 70
        Row{
            id: bullets
            width: 100
            height: 30
            z: 10
            spacing: 20
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right;
            anchors.rightMargin: 30
            Rectangle{
                width: 20
                height: 20
                color: "darkgrey"
                radius: 9
                opacity: .5
            }
            Rectangle{
                width: 20
                height: 20
                color: "grey"
                radius: 9
                opacity: .5
            }
            Rectangle{
                width: 20
                height: 20
                color: "darkgrey"
                radius: 9
                opacity: .5
            }
        }
        ShadowUp{
            anchors.bottom: parent.bottom
            width: parent.width
        }
    }
    Pager {
        property bool firstTime : true
        id: myPager
        isHorizontal: true
        model: pagesModel
        color: "transparent"
        enableKeys: true
        focus: true
        startIndex: 1
        anchors.fill: parent
        Timer {
            id: pagertimer
            interval: 100; running: false; repeat: false
            onTriggered: {
                if (parent.index==1) {
                    if (parent.firstTime) parent.firstTime = false; else mn.setNumbers()
                    tf.forceActiveFocus()
                }
                if (parent.index==0) mn.setABC()
                for (var i=0; i<bullets.children.length; i++) bullets.children[i].color = "darkgrey"
                bullets.children[parent.index].color = "grey"
            }
        }

        onIndexChanged: {
            pagertimer.running = true
        }

    }

    VisualItemModel {
        id: pagesModel
///////////////////////////////page 1
        Rectangle {
            width: appWindow.width
            height: appWindow.height
            color: "transparent"
            Column {
                id: pageOneTopColumn
                spacing: 10
                anchors.top: parent.top
                width: parent.width
                Rectangle{
                    height: 72
                    width: parent.width
                    color: "transparent"
                    TitleText {
                        text: "functions + constants"
                    }
                }
                TextField{
                    id: searchFunctions
                    inputMethodHints: Qt.ImhNoPredictiveText;
                    width: parent.width - 40
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
            ListView{
                id: funcsnconsts
                clip: true
                width: parent.width
                anchors.top: pageOneTopColumn.bottom
                anchors.bottom: insertButton.top
                anchors.bottomMargin: 20
                model: {eval(mn.getFunctions(searchFunctions.text))}
                delegate: Rectangle{
                    property variant functionData: modelData
                    color: ListView.isCurrentItem ? Qt.rgba(0,0,0,0.3) : "transparent"
                    height: 50
                    width: parent.width
                    Text{
                        id:textitem
                        text:modelData.name
                        color: "white"
                        width: parent.width -40
                        font.pixelSize: 40
                        anchors.centerIn: parent
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
//                                    webBusy.visible = true;
                                funcsnconsts.currentIndex = index;
                            }
                            onDoubleClicked: insertFn(modelData)
                        }
                    }
                }
            }

            Button{
                id: insertButton
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                width: parent.width - 50
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: insertFn(funcsnconsts.currentItem.functionData)
                text: "append to expression"
            }


        }
///////////////////////////////page 2
        Rectangle{
            width: appWindow.width
            height: appWindow.height
            color: "transparent"
            Column{
                anchors.fill: parent
                anchors.margins: 20
                ListModel{
                    id: resultsList
                }
                Rectangle{
                    height: 70
                    width: parent.width
                    color: "transparent"
                }

                Rectangle{
                    height: parent.height/3
                    width: parent.width
                    color: "transparent"
                    ListView{
                        clip: true
                        id: resultsView
                        snapMode: "SnapOneItem"
                        height: parent.height
                        width: parent.width
                        model: resultsList
                        delegate: MouseArea{
                            height: 40
                            width: parent.width
                            Text{
                                id: li
                                text:model.text
                                font.pixelSize: 30
                                color: "white"
                            }
                            onClicked: {
                                if (mouse.wasHeld)
                                    tf.text = tf.text + model.value
                                else
                                    tf.text = tf.text + "(" +model.steps + ")"
                                mouse.accepted = true;
                                tf.forceActiveFocus()
                            }
            //                onClicked: {
            //                    tf.text = tf.text + model.value
            //                    tf.forceActiveFocus()

            //                }
                        }

                    }
//                    ScrollDecorator{
//                        flickableItem: resultsView
//                    }
                }


                Text{
                    //margintop 30
                    id: result
                    color: "white"
                    font.pointSize: 12
                    height: 100
                    width: parent.width
                }
                Row{
                    width: parent.width
                    height: childrenRect.height
                    spacing: 10
                    TextField{
                        id: tf
                        width: parent.width - goButton.width - parent.spacing
                        inputMethodHints: Qt.ImhNoPredictiveText;
                        placeholderText: "expression"
                        Keys.onReturnPressed: { go();}
//                        Rectangle{
//                            anchors.left:parent.left
//                            anchors.top:parent.top
//                            anchors.leftMargin: tf.positionToRectangle(4).x
//                            anchors.topMargin: tf.positionToRectangle(4).y
//                            height: 20
//                            width:20
//                            color: "blue"
//                        }

                        Image {
                                anchors { verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: (parent.height - height) / 2; }
                                id: clearText
                                fillMode: Image.PreserveAspectFit
                                smooth: true;
                                visible: tf.text
                                source: "clear.svg"
                                height: parent.height * 0.7
                                width: height
                                MouseArea {
                                    id: clear
                                    anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
                                    height: tf.height; width: tf.height
                                    onClicked: {
                                        tf.text = ""
                                        tf.forceActiveFocus()
                                    }
                                }
                            }
                        onTextChanged: {
                            if (mn.autoCalc(text)!=="NaN") result.text= mn.autoCalc(text)
                        }

                        //focus: visible//myPager.index==0
                    }
                    Button {
                        id: goButton
                        text: "Go"
                        width: 100
                        onClicked: { go();  }
                    }
                }
                Column{
                    width: parent.width
                    height: childrenRect.height
                    spacing: 10
                    //color: "transparent"
                    Rectangle{
                        width: parent.width
                        height: 10
                        color: "transparent"
                    }
//                    Button {
//                        anchors.horizontalCenter: parent.horizontalCenter
//                        width: 400
//                        text: "clear till"
//                        onClicked: resultsList.clear()
//                    }
//                    Button {
//                        anchors.horizontalCenter: parent.horizontalCenter
//                        width: 400
//                        text: "copy result"
//                        enabled: result.text.lengthx
//                        onClicked: mn.setClipboard(result.text)
//                    }
                }
            }
        }

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
                    font.pixelSize: 40
                    anchors.left: parent.left;
                    anchors.leftMargin: 30
                }
                Text{
                    text: "Double tap on any function in the functions page to insert it to the running expression."
                    color: "white"
                    width: parent.width - 90
                    font.pixelSize: 30
                    wrapMode: "WordWrap"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Rectangle{
                    color: "transparent"
                    height: 20
                    width: parent.width
                }
                Text{
                    text: "Swipe in from the bottom left corner of the screen to bring up the native virtual keyboard, so you can type complex expressions."
                    color: "white"
                    width: parent.width - 90
                    font.pixelSize: 30
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
                    font.pixelSize: 30
                    wrapMode: "WordWrap"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

            }
        }
    }
    Component.onCompleted: {
        tf.forceActiveFocus();

    }

    function go(){
        if (mn.calc(tf.text) !== "")
            resultsList.append({"text": tf.text + " = " + mn.calc(tf.text), "value" : mn.calc(tf.text), "steps" : tf.text})
        else
            resultsList.append({"text": tf.text, "value" : tf.text, "steps": tf.text})
        tf.forceActiveFocus()
        resultsView.positionViewAtEnd()
    }

    function insertFn(data){
        var parenthesis = data.func?"()":""
        tf.text = tf.text + data.val + parenthesis
        if (data.func) tf.cursorPosition = tf.text.length -1
        myPager.goToPage(1)
    }

}

