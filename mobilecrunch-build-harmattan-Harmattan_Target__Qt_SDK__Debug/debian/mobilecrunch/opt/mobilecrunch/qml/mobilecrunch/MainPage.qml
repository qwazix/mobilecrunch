import QtQuick 1.1
import com.nokia.meego 1.0
import QtQuick 1.0
import QtMobility.contacts 1.1

Page {
    //tools: commonTools
    orientationLock: PageOrientation.LockPortrait

    Pager {
        id: myPager
        isHorizontal: true
        model: pagesModel
        color: "transparent"
        enableKeys: true
        focus: true
        anchors {fill:parent}
        Timer {
            id: pagertimer
            interval: 100; running: false; repeat: false
            onTriggered: if (parent.index==0) tf.forceActiveFocus()
        }

        onIndexChanged: {
            pagertimer.running = true
        }
    }

    VisualItemModel {
        id: pagesModel
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
                    height: 350
                    width: parent.width
                    color: "transparent"
                    ListView{
                        id: resultsView

                        snapMode: "SnapOneItem"
                        height: 350
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
                        onClicked: {
                            if (mn.calc(tf.text) !== "")
                                resultsList.append({"text": tf.text + " = " + mn.calc(tf.text), "value" : mn.calc(tf.text), "steps" : tf.text})
                            else
                                resultsList.append({"text": tf.text, "value" : tf.text, "steps": tf.text})
                            tf.forceActiveFocus()
                            resultsView.positionViewAtEnd()
                        }
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
                Text {
                    text: "asdgf"
                }
            }
        }
        Rectangle {
            width: 480
            height: 800
            color: "transparent"
            Column {
                anchors.fill: parent
                Text {
                    text: "page3"
                }
            }
        }
    }
    Component.onCompleted: {
        tf.forceActiveFocus();

    }

}


