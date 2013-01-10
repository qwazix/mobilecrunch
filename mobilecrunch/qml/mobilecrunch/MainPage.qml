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
                    if (parent.firstTime) parent.firstTime = false; //else mn.setNumbers()
//                    tf.forceActiveFocus()
                }
                //if (parent.index==0) mn.setABC()
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
///////////////////////////////////////////// Page 1
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
                    height: 70
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

        ///////////////////////////////////////////////// page 2
        Rectangle{
            width: appWindow.width
            height: appWindow.height
            color: "transparent"
            Column{
                anchors.fill: parent
                anchors.margins: 20
                spacing: 10
                ListModel{
                    id: resultsList
                }
                Rectangle{
                    height: 70
                    width: parent.width
                    color: "transparent"
                }

                Rectangle{
                    height: parent.height/4
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
                            height: 50
                            width: parent.width
                            Text{
                                id: li
                                text:model.text
                                font.pixelSize: 40
                                color: "white"
                            }
                            onClicked: {
                                if (mouse.wasHeld)
                                    tf.text = tf.text + model.value
                                else
                                    tf.text = tf.text + "(" +model.steps + ")"
                                mouse.accepted = true;
        //                                tf.forceActiveFocus()
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

        //        Button{
        //            text: "kbheight";
        //            onClicked: {
        //                console.log(mn.getKeyboardHeight());
        //            }
        //        }
                VkbState {
                    id: vkbState;
                }

                Row{
                    width: parent.width
                    height: childrenRect.height
                    spacing: 10
                    TextField{
                        id: tf
                        property bool isFocused;
                        width: parent.width - goButton.width - parent.spacing - (vkbState.open?(hidekb.width):0 )
                        inputMethodHints: Qt.ImhNone;
        //                        inputMethodHints: Qt.ImhPreferNumbers
        //                        onActiveFocusChanged: {
        //                            tfTimer.start();
        //                            tf.isFocused = focus;
        //                            hidekb.forceHidden=false;
        //                            if (focus) width= parent.width - goButton.width - parent.spacing - (hidekb.width + parent.spacing); else width = parent.width - goButton.width - parent.spacing
        //                        }

        //                        Timer {
        //                            id: tfTimer
        //                            interval: 50; running: false; repeat: false
        //                            onTriggered: {
        //                               mn.hideKeyboard();
        //                               running = false;
        //                            }
        //                        }

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
        //                                        tf.forceActiveFocus()
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

                    MouseArea{
                        id: hidekb
        //                property bool forceHidden;
                        width: 100
                        height: 61
                        anchors.top: parent.top
                        anchors.topMargin: tf.height - hidekb.height
                        Image {
                            source: "hidekb.svg"
                        }
                        onClicked: {
                            mn.hideKeyboard();
        //                    hidekb.forceHidden = true
                        }
                        visible: vkbState.open;
                    }
                }
                Rectangle{
                    width: parent.width
                    height: 20;
                    color: "transparent"
                }
                Row{
                    id: pageIndicatorBars
                    width: childrenRect.width
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 10
                    z: 10
                    spacing: 10
                    Rectangle{
                        width: 200
                        height: 8
                        color: "grey"
                        opacity: .8
                    }
                    Rectangle{
                        width: 200
                        height: 8
                        color: "darkgrey"
                        opacity: .8
                    }
                }
                Pager {
                    property bool firstTime : true
                    id: buttonsPager
                    isHorizontal: true
                    color: "transparent"
                    enableKeys: false
                    focus: false
                    startIndex: 0
                    spacing: 20
                    height : parent.height /2 - 130
                    width: parent.width
                    model: VisualItemModel {
                        // Page 1
                        Grid{
                            id: buttonsPage0
                            columns: 5
                            rows: 4
                            width: parent.parent.width
                            spacing: 15
                            height: parent.height
                            CalcButton {text: "7"}
                            CalcButton {text: "8"}
                            CalcButton {text: "9"}
                            CalcButton {text: "+"}
                            Backspace {}
                            CalcButton {text: "4"}
                            CalcButton {text: "5"}
                            CalcButton {text: "6"}
                            CalcButton {text: "-"}
                            CalcButton {text: "("}
                            CalcButton {text: "1"}
                            CalcButton {text: "2"}
                            CalcButton {text: "3"}
                            CalcButton {text: "*"}
                            CalcButton {text: ")"}
                            CalcButton {text: "."}
                            CalcButton {text: "0"}
                            CalcButton {text: "000"}
                            CalcButton {text: "/"}
                            CalcButton {text: "^"}
                        }
                        //Page 2
                        Grid{
                            columns: 5
                            rows: 4
                            width: buttonsPage0.width
                            spacing: 15
                            height: parent.height
                            CalcButton {text: "sin"; isFunction: true }
                            CalcButton {text: "cos"; isFunction: true}
                            CalcButton {text: "tan"; isFunction: true}
                            CalcButton {text: "pi"}
                            Backspace {}
                            CalcButton {text: "asin"; isFunction: true}
                            CalcButton {text: "acos"; isFunction: true}
                            CalcButton {text: "atan"; isFunction: true}
                            CalcButton {Image { source: "squareroot.svg"; anchors.centerIn: parent } value: "sqrt()"}
                            CalcButton {Image { source: "cubicroot.svg"; anchors.centerIn: parent} value:"^-3"; onCallback: {tf.cursorPosition -= 3}}
                            CalcButton {text: "("}
                            CalcButton {text: "!"}
                            CalcButton {text: "e"}
                            CalcButton {text: "%"}
                            CalcButton {text: ")"}
                            CalcButton {text: "x="}
                            CalcButton {text: "home"
                                        special: true
                                        onRunFunction: tf.cursorPosition = 0
                                        }
                            CalcButton {text: "←"
                                        special: true
                                        onRunFunction: {
                                            tf.forceActiveFocus();
                                            mn.hideKeyboard();
                                            tf.cursorPosition--
                                        }}
                            CalcButton {text: "→";
                                        special: true
                                        onRunFunction: {
                                            tf.forceActiveFocus();
                                            mn.hideKeyboard();
                                            tf.cursorPosition++
                                        }}
                            CalcButton {text: "end"
                                        special: true
                                        onRunFunction: {
                                            tf.forceActiveFocus();
                                            mn.hideKeyboard();
                                            tf.cursorPosition = tf.text.length
                                        }}
                            //←↑→↓
                        }

                    }
                    Timer {
                        id: pagertimerBtn
                        interval: 100; running: false; repeat: false
                        onTriggered: {
                            if (parent.index==1) {
                                if (parent.firstTime) parent.firstTime = false; //else mn.setNumbers()
        //                                tf.forceActiveFocus()
                            }
                            //if (parent.index==0) mn.setABC()
                            for (var i=0; i<pageIndicatorBars.children.length; i++) pageIndicatorBars.children[i].color = "grey"
                            pageIndicatorBars.children[parent.index].color = "#489bc0"
                        }
                    }

                    onIndexChanged: {
                        pagertimerBtn.running = true
                    }

                }
                Rectangle{
                    width: parent.width
                    height: 3
                    color: "transparent"
                }
                Row{
                    width: childrenRect.width
                    height: childrenRect.height
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10
                    //color: "transparent"
                    Button {
                        text: "clear till"
                        onClicked: resultsList.clear()
                    }
                    Button {
                        width: 100
                        iconSource: "copy.svg"
                        enabled: result.text.length
                        onClicked: mn.setClipboard(result.text)
                    }
                    KeyboardButton {
                        width: 100
                        iconSource: "paste.svg"
                        value: mn.getClipboard();
                        onBeforeClicked: {
                            value = mn.getClipboard();
                        }
                    }
                }
            }
        }


        Page3{}
    }
    Component.onCompleted: {
//        tf.forceActiveFocus();
        mn.changeKeyboardType(1);
    }

    function go(){
        if (mn.calc(tf.text) !== "")
            resultsList.append({"text": tf.text + " = " + mn.calc(tf.text), "value" : mn.calc(tf.text), "steps" : tf.text})
        else
            resultsList.append({"text": tf.text, "value" : tf.text, "steps": tf.text})
//        tf.forceActiveFocus()
        resultsView.positionViewAtEnd()
    }

    function insertFn(data){
        var parenthesis = data.func?"()":""
        tf.text = tf.text + data.val + parenthesis
        if (data.func) tf.cursorPosition = tf.text.length -1
        myPager.goToPage(1)
    }

}

