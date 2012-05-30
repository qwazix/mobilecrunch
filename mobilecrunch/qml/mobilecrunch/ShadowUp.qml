import QtQuick 1.0

Column {
    id: shadowUp
    Rectangle{
        width: parent.width
        height: 2
        color: Qt.rgba(0,0,0,0.05)
    }
    Rectangle{
        width: parent.width
        height: 1
        color: Qt.rgba(0,0,0,0.1)
    }
    Rectangle{
        width: parent.width
        height: 1
        color: Qt.rgba(0,0,0,0.2)
    }
    Rectangle{
        width: parent.width
        height: 1
        color: Qt.rgba(0,0,0,0.3)
    }
}
