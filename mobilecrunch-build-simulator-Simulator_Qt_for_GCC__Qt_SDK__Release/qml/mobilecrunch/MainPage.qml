import QtQuick 1.1
import com.nokia.meego 1.0
import QtQuick 1.0
import QtWebKit 1.0

Page {
    //tools: commonTools
    orientationLock: PageOrientation.LockPortrait
    Rectangle{
        color: "#fcbd0b"
        width: parent.width
        height: 70
        Row{
            id: bullets
            width: 100
            height: 30
            z: 10
            spacing: 20
            anchors.top: parent.top;
            anchors.left: parent.left;
            anchors.leftMargin: 200
            anchors.topMargin: 20
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
        anchors {fill:parent}
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
            width: 480
            height: 800
            color: "transparent"
            Column {
                spacing: 10
                anchors.fill: parent
                Rectangle{
                    height: 72
                    width: parent.width
                    color: "transparent"
                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.topMargin: 17
                        text: "functions"
                        font.pixelSize: 30
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.rightMargin: 20
                        anchors.topMargin: 17
                        text: "constants"
                        font.pixelSize: 30
                    }
                }
                TextField{
                    id: searchFunctions
                    placeholderText: "search"
                    inputMethodHints: Qt.ImhNoPredictiveText;
                    width: parent.width - 40
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                ListView{
                    id: funcsnconsts
                    clip: true
                    width: parent.width

                    height: 300
                    model: {eval(mn.getFunctions(searchFunctions.text))}
                    delegate: Rectangle{
                        color: ListView.isCurrentItem ? "#fcbd0b" : "transparent"
                        height: 50
                        width: parent.width
                        Text{
                            id:textitem
                            text:modelData.name
                            width: parent.width -40
                            font.pixelSize: 30
                            anchors.centerIn: parent
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    webBusy.visible = true;
                                    funcsnconsts.currentIndex = index;
                                }
                                onDoubleClicked: {
                                    var parenthesis = modelData.func?"()":""
                                    tf.text = tf.text + modelData.val + parenthesis
                                    if (modelData.func) tf.cursorPosition = tf.text.length -1
                                    myPager.goToPage(1)
                                }
                            }
                        }
                    }
                }
                Flickable{
                    flickableDirection: "VerticalFlick"
                    clip: true
                    id: webFlick
                    height: 400
                    contentHeight: refWeb.contentsSize.height
                    width: parent.width
                    BusyIndicator{
                        id: webBusy
                        platformStyle: BusyIndicatorStyle { size: "large" }
                        visible: false
                        running: true
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 90
                        z: 10
                    }
                    WebView {
                        id: refWeb
                        contentsScale: 1.6
                        preferredWidth: 480/contentsScale
                        preferredHeight: 400
                        height: 6000
                        anchors.horizontalCenter: parent.horizontalCenter;
                        anchors.top: parent.top;
                        anchors.topMargin: -70
                        width: 480
                        url: "http://en.m.wikipedia.org/w/index.php?title=Special%3ASearch&search=" + funcsnconsts.currentItem.children[0].text.replace(" ","+","g")
                        //onUrlChanged: heuristicZoom(10,10,2);//evaluateJavaScript("document.getElementsByTagName('html')[0].scrollTop = 30")
                        onProgressChanged: if (progress==1) webBusy.visible = false//function() {return refWeb.progress!=1}
                    }

                }
                ScrollDecorator{
                    flickableItem: webFlick
                    height: 0
                }
            }
        }
///////////////////////////////page 2
        Rectangle{
            width: 480
            height: 800
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
                    height: 280
                    width: parent.width
                    color: "transparent"
                    ListView{
                        clip: true
                        id: resultsView
                        snapMode: "SnapOneItem"
                        height: 280
                        width: parent.width
                        model: resultsList
                        delegate: MouseArea{
                            height: 40
                            width: parent.width
                            Text{
                                id: li
                                text:model.text
                                font.pixelSize: 30
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
                    ScrollDecorator{
                        flickableItem: resultsView
                    }
                }


                Text{
                    //margintop 30
                    id: result
                    font.pointSize: 30
                    height: 70
                    width: parent.width
                }
                Row{
                    TextField{
                        id: tf
                        width: 370
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
                                anchors { top: parent.top; right: parent.right; margins: 7 }
                                id: clearText
                                fillMode: Image.PreserveAspectFit
                                smooth: true;
                                visible: tf.text
                                source: "clear.svg"
                                height: parent.height - 14
                                width: parent.height - 14
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
                        text: "Go"
                        width: 70
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
                    Button {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 400
                        text: "clear till"
                        onClicked: resultsList.clear()
                    }
                    Button {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 400
                        text: "copy result"
                        enabled: result.text.lengthx
                        onClicked: mn.setClipboard(result.text)
                    }
                }
            }
        }

        Rectangle {
            width: 480
            height: 800
            color: "transparent"
            Column {
                anchors.fill: parent
                Rectangle{
                    height: 90
                    width: parent.width
                    color: "transparent"
                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.topMargin: 17
                        text: "settings"
                        font.pixelSize: 30
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.rightMargin: 20
                        anchors.topMargin: 17
                        text: "help"
                        font.pixelSize: 30
                    }
                }
                ButtonRow{
                    anchors.horizontalCenter: parent.horizontalCenter
                    Button{
                        platformStyle : ButtonStyle {
                                    checkedBackground: "image://theme/" + "color19-" + "meegotouch-button"+__invertedString+"-background-selected-horizontal-left"
                                    pressedBackground: "image://theme/" + "color19-" + "meegotouch-button"+__invertedString+"-background-pressed-horizontal-left"
                                }

                        text: "degrees"
                        onClicked: {
                            mn.setAngleModeDegree()
                            result.text= mn.autoCalc(tf.text)
                            console.log(mn.getAngleMode()=='d')
                        }
                        checked: {return (mn.getAngleMode() == 'd')}
                    }
                    Button{
                        platformStyle : ButtonStyle {
                                    checkedBackground: "image://theme/" + "color19-" + "meegotouch-button"+__invertedString+"-background-selected-horizontal-right"
                                    pressedBackground: "image://theme/" + "color19-" + "meegotouch-button"+__invertedString+"-background-pressed-horizontal-right"
                                }
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
                    width: parent.width - 60
                    font.pixelSize: 40
                    anchors.left: parent.left;
                    anchors.leftMargin: 30
                }
                Text{
                    text: "Double tap on any function in the functions page to insert it to the running expression."
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

}

