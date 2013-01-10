import QtQuick 1.1

CalcButton {
    Image {
        source: "backspace.svg"
        anchors.centerIn: parent
    }
    special: true;
    onRunFunction: {
        var txt = tf.text
        var res;
        var pos = tf.cursorPosition;
        if (txt == "") return;
        if (pos == 0) return;
        if (tf.selectionStart - tf.selectionEnd !=0) {
            var firstpart = txt.slice(0, tf.selectionStart);
            var lastpart = txt.slice(tf.selectionEnd);
            res = firstpart + "" + lastpart
            return
        }
        if (pos == tf.text.length) {
            tf.text = tf.text.slice(0, tf.text.length-1)
            return
        }
        if (pos < tf.text.length){
            var firstpart = txt.slice(0, pos-1);
            var lastpart = txt.slice(pos);
            tf.text = firstpart + "" + lastpart
            tf.cursorPosition = pos-1
        }
    }
}
