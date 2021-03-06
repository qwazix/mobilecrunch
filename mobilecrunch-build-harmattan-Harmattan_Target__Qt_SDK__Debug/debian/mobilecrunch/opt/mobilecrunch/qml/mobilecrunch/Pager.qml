import QtQuick 1.0

Rectangle {
    id:pager
    anchors.fill: parent

    property bool enableKeys: true
    property QtObject model
    property bool isHorizontal: false

    property int index: view.currentIndex
    property Item item: view.currentItem

    signal indexChanged


    ListView {

        id: view
        anchors.fill: pager
        model: pager.model
        orientation: if (isHorizontal){ListView.Horizontal;} else {ListView.Vertical}
        snapMode: ListView.SnapOneItem;
        flickDeceleration: 500
        highlightFollowsCurrentItem: true
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: 0; preferredHighlightEnd: 0
        cacheBuffer: width;
        focus: pager.focus
        onCurrentIndexChanged: pager.indexChanged()
        Keys.onLeftPressed: {
            if (enableKeys && isHorizontal && (currentIndex > 0 ))
            currentIndex = currentIndex-1;}
        Keys.onRightPressed: {
            if (enableKeys && isHorizontal && (currentIndex < count))
            currentIndex = currentIndex+1;}
        Keys.onUpPressed: {
            if (enableKeys && !isHorizontal && (currentIndex > 0 ))
            currentIndex = currentIndex-1;}
        Keys.onDownPressed: {
            if (enableKeys && !isHorizontal && (currentIndex < count))
            currentIndex = currentIndex+1;}
    }
}
