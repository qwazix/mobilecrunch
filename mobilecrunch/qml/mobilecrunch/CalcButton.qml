import QtQuick 1.1
import "UIConstants.js" as UI

Button {
    id: calcButton
    property alias text: calcButton.text
    property bool special;
    signal runFunction
    signal callback
    property bool isFunction: false
    property variant value: calcButton.text + (isFunction?"()":"")
    width: parent.width/parent.columns - parent.spacing*(parent.columns-1)/parent.columns;
    height: UI.BUTTON_HEIGHT * 1.5
    onClicked: {
        if (!special){
            var txt = tf.text
            var res;
            var pos = tf.cursorPosition
            if (txt=="") tf.text = value; else {
                if (tf.selectionStart - tf.selectionEnd !=0) {
                    var firstpart = txt.slice(0, tf.selectionStart);
                    var lastpart = txt.slice(tf.selectionEnd);
                    res = firstpart + "" + value + "" + lastpart
                } else {
                    if (pos == 0){
                        res= value + "" + tf.text
                    } else if (pos == tf.text.length){
                        console.log(0)
                        res=tf.text +""+ value;
                    } else {
                        var rgx = new RegExp("(.{1,"+pos+"})(.*)");
                        var chunks = txt.match(rgx);
                        chunks = chunks.slice(1)
                        console.log(chunks)
                        res = chunks.join(value);
                    }
                }
                tf.text = res;
                tf.cursorPosition = pos+value.length
            }
            if (value.slice(-2) == "()") tf.cursorPosition--
            calcButton.callback();
        } else {
            calcButton.runFunction();
        }
    }
}
