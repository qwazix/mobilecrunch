TEMPLATE = app

# Additional import path used to resolve QML modules in Creator's code model
QML_IMPORT_PATH =
LIBS += -lbbdevice

# If your application uses the Qt Mobility libraries, uncomment the following
# lines and add the respective components to the MOBILITY variable.
# CONFIG += mobility
# MOBILITY +=

# Add dependency to Symbian components
# CONFIG += qt-components

# The .cpp file which was generated for your project. Feel free to hack it.
SOURCES += main.cpp \
    core/constants.cpp \
    core/evaluator.cpp \
    core/functions.cpp \
    core/settings.cpp \
    math/floatcommon.c \
    math/floatconst.c \
    math/floatconvert.c \
    math/floaterf.c \
    math/floatexp.c \
    math/floatgamma.c \
    math/floathmath.c \
    math/floatincgamma.c \
    math/floatio.c \
    math/floatipower.c \
    math/floatlog.c \
    math/floatlogic.c \
    math/floatlong.c \
    math/floatnum.c \
    math/floatpower.c \
    math/floatseries.c \
    math/floattrig.c \
    math/hmath.cpp \
    math/number.c \
    bison/bisonparser.cpp \
    bison/exprparser.c \
    manager.cpp

# Please do not modify the following line. Required for deployment.
include(qmlapplicationviewer/qmlapplicationviewer.pri)

OTHER_FILES += \
    bison/exprparser.y \
    clear.svg \
    textfield.png \
    background.png \
    button-background.png button-background-pressed.png \
    button-background-horizontal-right.png button-background-horizontal-left.png \
    button-background-selected-horizontal-right.png button-background-selected-horizontal-left.png\
    button-background-pressed-horizontal-right.png button-background-pressed-horizontal-left.png\
    button-background-selected.png \
    qml/mobilecrunch/Pager.qml \
    qml/mobilecrunch/ShadowUp.qml \
    bar-descriptor.xml \
    qml/mobilecrunch/MainPage.qml \
    qml/mobilecrunch/main.qml \
    qml/mobilecrunch/UIConstants.js \
    qml/mobilecrunch/TextFieldStyle.qml \
    qml/mobilecrunch/TextField.qml \
    qml/mobilecrunch/Magnifier.js \
    qml/mobilecrunch/EditBubble.js \
    qml/mobilecrunch/Magnifier.qml \
    qml/mobilecrunch/EditBubbleStyle.qml \
    qml/mobilecrunch/EditBubbleButtonStyle.qml \
    qml/mobilecrunch/EditBubbleButton.qml \
    qml/mobilecrunch/EditBubble.qml \
    qml/mobilecrunch/TitleText.qml \
    qml/mobilecrunch/ButtonGroup.js \
    qml/mobilecrunch/ButtonStyle.qml \
    qml/mobilecrunch/ButtonRow.qml \
    qml/mobilecrunch/Button.qml \
    qml/mobilecrunch/LabelStyle.qml \
    qml/mobilecrunch/Label.qml \
    qml/mobilecrunch/Style.qml

HEADERS += \
    core/constants.h \
    core/errors.h \
    core/evaluator.h \
    core/functions.h \
    core/settings.h \
    math/floatcommon.h \
    math/floatconfig.h \
    math/floatconst.h \
    math/floatconvert.h \
    math/floaterf.h \
    math/floatexp.h \
    math/floatgamma.h \
    math/floathmath.h \
    math/floatincgamma.h \
    math/floatio.h \
    math/floatipower.h \
    math/floatlog.h \
    math/floatlogic.h \
    math/floatlong.h \
    math/floatnum.h \
    math/floatpower.h \
    math/floatseries.h \
    math/floattrig.h \
    math/hmath.h \
    math/number.h \
    bison/bison.h \
    bison/bisonparser.h \
    bison/exprparser.h \
    manager.h















