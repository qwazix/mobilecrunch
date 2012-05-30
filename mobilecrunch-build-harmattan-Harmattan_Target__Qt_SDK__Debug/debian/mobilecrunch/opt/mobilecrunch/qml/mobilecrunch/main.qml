import QtQuick 1.1
import com.nokia.meego 1.0
import QtQuick 1.0


PageStackWindow {
    id: appWindow

    initialPage: mainPage

//    Flickable{
//        anchors.fill: parent;

//    }

    MainPage {
        id: mainPage
    }

//    ToolBarLayout {
//        id: commonTools
//        visible: true
//        ToolIcon {
//            platformIconId: "toolbar-view-menu"
//            anchors.right: (parent === undefined) ? undefined : parent.right
//            onClicked: (myMenu.status == DialogStatus.Closed) ? myMenu.open() : myMenu.close()
//        }
//    }

//    Menu {
//        id: myMenu
//        visualParent: pageStack
//        MenuLayout {
//            MenuItem { text: qsTr("Sample menu item") }
//        }
//    }
    Text{
        visible: false;
        text: Qt.application.active
        onTextChanged: {
            if (Qt.application.active)
                mn.loadLayouts()
            else
                mn.restoreLayouts()
        }
    }
}
