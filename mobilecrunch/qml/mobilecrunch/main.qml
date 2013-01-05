import QtQuick 1.1
import QtQuick 1.0


Rectangle {
    id: appWindow
    color: "white"
//    width: screen.displayWidth
//    height: screen.displayHeight
    width: 768
    height: 1280

    MainPage {
        id: mainPage
    }

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
