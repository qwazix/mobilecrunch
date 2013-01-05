/****************************************************************************
**
** Copyright (C) 2011 Nokia Corporation and/or its subsidiary(-ies).
** All rights reserved.
** Contact: Nokia Corporation (qt-info@nokia.com)
**
** This file is part of the Qt Components project.
**
** $QT_BEGIN_LICENSE:BSD$
** You may use this file under the terms of the BSD license as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of Nokia Corporation and its Subsidiary(-ies) nor
**     the names of its contributors may be used to endorse or promote
**     products derived from this software without specific prior written
**     permission.
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 1.1
import "." 1.0
import "UIConstants.js" as UI
import "EditBubble.js" as Popup
import "TextAreaHelper.js" as TextAreaHelper
import "Magnifier.js" as MagnifierPopup
FocusScope {
    id: root

    // Common public API
    property alias text: textInput.text
    property alias placeholderText: prompt.text

    property alias inputMethodHints: textInput.inputMethodHints
    property alias font: textInput.font
    property alias cursorPosition: textInput.cursorPosition
    property alias maximumLength: textInput.maximumLength
    property alias readOnly: textInput.readOnly
    property alias acceptableInput: textInput.acceptableInput
    property alias inputMask: textInput.inputMask
    property alias validator: textInput.validator

    property alias selectedText: textInput.selectedText
    property alias selectionStart: textInput.selectionStart
    property alias selectionEnd: textInput.selectionEnd

    property alias echoMode: textInput.echoMode // ### TODO: declare own enum { Normal, Password }

    property bool errorHighlight: !acceptableInput
    // Property enableSoftwareInputPanel is DEPRECATED
    property alias enableSoftwareInputPanel: textInput.activeFocusOnPress

    property Item platformSipAttributes

    property bool platformEnableEditBubble: true

    property Item platformStyle: TextFieldStyle {}

    property alias style: root.platformStyle

    property Component customSoftwareInputPanel

    property Component platformCustomSoftwareInputPanel

//    property alias platformPreedit: inputMethodObserver.preedit

    onPlatformSipAttributesChanged: {
        platformSipAttributes.registerInputElement(textInput)
    }

    onCustomSoftwareInputPanelChanged: {
        console.log("TextField's property customSoftwareInputPanel is deprecated. Use property platformCustomSoftwareInputPanel instead.")
        platformCustomSoftwareInputPanel = customSoftwareInputPanel
    }

    onPlatformCustomSoftwareInputPanelChanged: {
        textInput.activeFocusOnPress = platformCustomSoftwareInputPanel == null
    }

    function copy() {
        textInput.copy()
    }

    function paste() {
        textInput.paste()
    }

    function cut() {
        textInput.cut()
    }

    function select(start, end) {
        textInput.select(start, end)
    }

    function selectAll() {
        textInput.selectAll()
    }

    function selectWord() {
        textInput.selectWord()
    }

    function positionAt(x) {
        var p = mapToItem(textInput, x, 0);
        return textInput.positionAt(p.x)
    }

    function positionToRectangle(pos) {
        var rect = textInput.positionToRectangle(pos)
        rect.x = mapFromItem(textInput, rect.x, 0).x
        return rect;
    }

    // ensure propagation of forceActiveFocus
    function forceActiveFocus() {
        textInput.forceActiveFocus()
    }

//    function closeSoftwareInputPanel() {
//        console.log("TextField's function closeSoftwareInputPanel is deprecated. Use function platformCloseSoftwareInputPanel instead.")
//        platformCloseSoftwareInputPanel()
//    }

//    function platformCloseSoftwareInputPanel() {
//        inputContext.simulateSipClose();
//        if (inputContext.customSoftwareInputPanelVisible) {
//            inputContext.customSoftwareInputPanelVisible = false
//            inputContext.customSoftwareInputPanelComponent = null
//            inputContext.customSoftwareInputPanelTextField = null
//        } else {
//            textInput.closeSoftwareInputPanel();
//        }
//    }

//    function openSoftwareInputPanel() {
//        console.log("TextField's function openSoftwareInputPanel is deprecated. Use function platformOpenSoftwareInputPanel instead.")
//        platformOpenSoftwareInputPanel()
//    }

    function platformOpenSoftwareInputPanel() {
        inputContext.simulateSipOpen();
        if (platformCustomSoftwareInputPanel != null && !inputContext.customSoftwareInputPanelVisible) {
            inputContext.customSoftwareInputPanelTextField = root
            inputContext.customSoftwareInputPanelComponent = platformCustomSoftwareInputPanel
            inputContext.customSoftwareInputPanelVisible = true
        } else {
            textInput.openSoftwareInputPanel();
        }
    }

    // private
    property bool __expanding: true // Layout hint used but ToolBarLayout

    implicitWidth: platformStyle.defaultWidth
    implicitHeight: UI.FIELD_DEFAULT_HEIGHT

//    onActiveFocusChanged: {
//        if (!readOnly) {
//            if (activeFocus) {
//                if (platformCustomSoftwareInputPanel != null) {
//                    platformOpenSoftwareInputPanel();
//                } else {
//                    inputContext.simulateSipOpen();
//                }

//                repositionTimer.running = true;
//            } else {
//                platformCloseSoftwareInputPanel();
//                Popup.close(textInput);
//            }
//        }
//    }


    BorderImage {
        id: background
        source: "textfield.png"
//        {
//            if(root.errorHighlight) return root.platformStyle.backgroundError
//            else if(root.readOnly) return root.platformStyle.backgroundDisabled
//            else if(textInput.activeFocus) return root.platformStyle.backgroundSelected
//            else return "textfield.png"
//        }
        anchors.fill: parent
        border.left: root.platformStyle.backgroundCornerMargin; border.top: root.platformStyle.backgroundCornerMargin
        border.right: root.platformStyle.backgroundCornerMargin; border.bottom: root.platformStyle.backgroundCornerMargin
    }

    Text {
        id: prompt

        anchors {verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right}
        anchors.leftMargin: root.platformStyle.paddingLeft
        anchors.rightMargin: root.platformStyle.paddingRight
        anchors.verticalCenterOffset: root.platformStyle.baselineOffset

        // memory allocation optimization: cursorPosition is checked to minimize displayText evaluations
        visible: textInput.cursorPosition == 0 && !textInput.text && prompt.text && !textInput.inputMethodComposing
//        font: root.platformStyle.textFont
        color: root.platformStyle.promptTextColor
        elide: Text.ElideRight
    }

    MouseArea {
        enabled: !textInput.activeFocus
        z: enabled?1:0
        anchors.fill: parent
        anchors.margins: UI.TOUCH_EXPANSION_MARGIN
        onClicked: {
            if (!textInput.activeFocus) {
                textInput.forceActiveFocus();
            }
        }
    }

    TextInput {
        id: textInput

//        property alias preedit: inputMethodObserver.preedit
//        property alias preeditCursorPosition: inputMethodObserver.preeditCursorPosition

        anchors {verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right}
        anchors.leftMargin: root.platformStyle.paddingLeft
        anchors.rightMargin: root.platformStyle.paddingRight
        anchors.verticalCenterOffset: root.platformStyle.baselineOffset

        passwordCharacter: "\u2022"
//        font: root.platformStyle.textFont
        color: root.platformStyle.textColor
        selectByMouse: true
        selectedTextColor: root.platformStyle.selectedTextColor
        selectionColor: root.platformStyle.selectionColor
        mouseSelectionMode: TextInput.SelectWords
        focus: true

        Component.onDestruction: {
            Popup.close(textInput);
        }

//        Connections {
//            target: TextAreaHelper.findFlickable(root.parent)

//            onContentYChanged: if (root.activeFocus) TextAreaHelper.filteredInputContextUpdate();
//            onContentXChanged: if (root.activeFocus) TextAreaHelper.filteredInputContextUpdate();
//            onMovementEnded: inputContext.update();
//        }

//        Connections {
//            target: platformWindow

//            onAnimatingChanged: {
//                if (!platformWindow.animating && root.activeFocus) {
//                    TextAreaHelper.repositionFlickable(contentMovingAnimation);
//                }
//            }
//        }

//        Connections {
//            target: inputContext

//            onSoftwareInputPanelRectChanged: {
//                if (activeFocus) {
//                    repositionTimer.running = true
//                }
//            }
//        }

        onTextChanged: {            
            if(root.activeFocus) {
                TextAreaHelper.repositionFlickable(contentMovingAnimation)
            }

            if (Popup.isOpened(textInput) && !Popup.isChangingInput())
                Popup.close(textInput);
        }

        onCursorPositionChanged: {
            var magnifier = MagnifierPopup.popup;
            if (magnifier) {
                var mappedPos =  mapToItem(magnifier.parent,positionToRectangle(cursorPosition).x - magnifier.width / 2, 0);
                magnifier.xCenter = positionToRectangle(cursorPosition).x / root.width;
                magnifier.x = mappedPos.x;
            }
            if (Popup.isOpened(textInput)) {
                Popup.close(textInput);
                Popup.open(textInput);
            }

        }

        onSelectedTextChanged: {
            if (Popup.isOpened(textInput) && !Popup.isChangingInput()) {
                Popup.close(textInput);
            }
        }

//        InputMethodObserver {
//            id: inputMethodObserver

//            onPreeditChanged: {
//                if(root.activeFocus) {
//                    TextAreaHelper.repositionFlickable(contentMovingAnimation)
//                }

//                if (Popup.isOpened(textInput) && !Popup.isChangingInput()) {
//                    Popup.close(textInput);
//                }
//            }
//        }

        Timer {
            id: repositionTimer
            interval: 350
            onTriggered: {
                TextAreaHelper.repositionFlickable(contentMovingAnimation)
            }
        }

        PropertyAnimation {
            id: contentMovingAnimation
            property: "contentY"
            duration: 200
            easing.type: Easing.InOutCubic
        }

//        MouseFilter {
//            anchors.fill: parent
//            anchors.leftMargin:  UI.TOUCH_EXPANSION_MARGIN - root.platformStyle.paddingLeft
//            anchors.rightMargin:  UI.TOUCH_EXPANSION_MARGIN - root.platformStyle.paddingRight
//            anchors.topMargin: UI.TOUCH_EXPANSION_MARGIN - ((root.height - parent.height) / 2)
//            anchors.bottomMargin:  UI.TOUCH_EXPANSION_MARGIN - ((root.height - parent.height) / 2)

//            property bool attemptToActivate: false
//            property bool pressOnPreedit: false

//            onPressed: {
//                var mousePosition = textInput.positionAt(mouse.x,TextInput.CursorOnCharacter);
//                pressOnPreedit = textInput.cursorPosition==mousePosition
//                var preeditDisabled = (
//                        root.inputMethodHints&
//                        (
//                                Qt.ImhHiddenText|
//                                Qt.ImhNoPredictiveText|
//                                Qt.ImhDigitsOnly|
//                                Qt.ImhFormattedNumbersOnly|
//                                Qt.ImhDialableCharactersOnly|
//                                Qt.ImhEmailCharactersOnly|
//                                Qt.ImhUrlCharactersOnly
//                )
//                );

//                attemptToActivate = !pressOnPreedit && !root.readOnly && !preeditDisabled && root.activeFocus && !(mousePosition == 0 || TextAreaHelper.atSpace(mousePosition - 1));
//                mouse.filtered = true;
//            }

//            onHorizontalDrag: {
//                // possible pre-edit word have to be commited before selection
//                if (root.activeFocus || root.readOnly) {
//                    inputContext.reset()
//                    parent.selectByMouse = true
//                    attemptToActivate = false
//                }
//            }

//            onPressAndHold:{
//                // possible pre-edit word have to be commited before showing the magnifier
//                if ((root.text != "" || inputMethodObserver.preedit != "") && root.activeFocus) {
//                    inputContext.reset()
//                    attemptToActivate = false
//                    MagnifierPopup.open(root);
//                    var magnifier = MagnifierPopup.popup;
//                    magnifier.xCenter = positionToRectangle(cursorPosition).x / root.width
//                    var mappedPos =  mapToItem(magnifier.parent, positionToRectangle(cursorPosition).x - magnifier.width / 2,
//                                               textInput.y - 120 - UI.MARGIN_XLARGE - (height / 2));
//                    var yAdjustment = -mapFromItem(magnifier.__rootElement(), 0, 0).y < magnifier.height / 2.5 ? magnifier.height / 2.5 + mapFromItem(magnifier.__rootElement(), 0,0).y : 0
//                    magnifier.x = mappedPos.x;
//                    magnifier.y = mappedPos.y + yAdjustment;
//                    magnifier.yCenter = 0.25;
//                    parent.cursorPosition = textInput.positionAt(mouse.x)
//                }
//            }
//            onReleased: {
//                if (MagnifierPopup.isOpened()) {
//                    MagnifierPopup.close();
//                }

//                if (attemptToActivate) {
//                    inputContext.reset();
//                    var beforeText = textInput.text;

//                    var newCursorPosition = textInput.positionAt(mouse.x,TextInput.CursorOnCharacter);

//                    var injectionSucceeded = false;

//                    if (!TextAreaHelper.atSpace(newCursorPosition)
//                             && !(newCursorPosition == textInput.text.length && TextAreaHelper.atSpace(newCursorPosition-1))
//                             && newCursorPosition != textInput.text.length) {
//                        var preeditStart = TextAreaHelper.previousWordStart(newCursorPosition);
//                        var preeditEnd = TextAreaHelper.nextWordEnd(newCursorPosition);

//                        // copy word to preedit text
//                        var preeditText = textInput.text.substring(preeditStart,preeditEnd);

//                        // inject preedit
//                        textInput.cursorPosition = preeditStart;

//                        var eventCursorPosition = newCursorPosition-preeditStart;

//                        injectionSucceeded = inputContext.setPreeditText(preeditText, eventCursorPosition, 0, preeditText.length);
//                    }
//                    if (injectionSucceeded) {
//                        mouse.filtered=true;
//                    } else {
//                        textInput.text=beforeText;
//                        textInput.cursorPosition=newCursorPosition;
//                    }
//                } else if (!parent.selectByMouse) {
//                    if (!pressOnPreedit) inputContext.reset();
//                    textInput.cursorPosition = textInput.positionAt(mouse.x,TextInput.CursorOnCharacter);
//                }

//                parent.selectByMouse = false;
//            }
//            onFinished: {
//                if (root.activeFocus && platformEnableEditBubble)
//                    Popup.open(textInput);
//            }

//            onMousePositionChanged: {
//                if (MagnifierPopup.isOpened() && !parent.selectByMouse) {
//                    parent.cursorPosition = textInput.positionAt(mouse.x)
//                }
//            }
//            onDoubleClicked: {
//                // possible pre-edit word have to be commited before selection
//                inputContext.reset()
//                parent.selectByMouse = true
//                attemptToActivate = false
//            }
//        }
    }

//    InverseMouseArea {
//        anchors.fill: parent
//        anchors.margins: UI.TOUCH_EXPANSION_MARGIN
//        enabled: textInput.activeFocus
//        onClickedOutside: {
//            if (Popup.isOpened(textInput) && ((mouseX > Popup.geometry().left && mouseX < Popup.geometry().right) &&
//                                           (mouseY > Popup.geometry().top && mouseY < Popup.geometry().bottom))) {
//                return;
//            }

//            root.platformCloseSoftwareInputPanel();
//            root.parent.focus = true;
//        }
//    }
}
