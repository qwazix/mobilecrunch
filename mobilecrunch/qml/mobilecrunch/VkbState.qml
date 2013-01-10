import QtQuick 1.1

Item {
    id: vkbState
    property bool open : false;
    Component.onCompleted: {
        mn.vkbVisible.connect(maketrue)
        mn.vkbHidden.connect(makefalse)
    }

    function maketrue(){
        vkbState.open = true;
        console.log("open")
    }

    function makefalse(){
        vkbState.open = false;
        console.log("closed")
    }

}
