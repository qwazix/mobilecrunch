# Add more folders to ship with the application, here
folder_01.source = qml/mobilecrunch
folder_01.target = qml
DEPLOYMENTFOLDERS = folder_01

# Additional import path used to resolve QML modules in Creator's code model
QML_IMPORT_PATH =

symbian:TARGET.UID3 = 0xE19422BD

# Smart Installer package's UID
# This UID is from the protected range and therefore the package will
# fail to install if self-signed. By default qmake uses the unprotected
# range value if unprotected UID is defined for the application and
# 0x2002CCCF value if protected UID is given to the application
#symbian:DEPLOYMENT.installer_header = 0x2002CCCF

# Allow network access on Symbian
symbian:TARGET.CAPABILITY += NetworkServices

# If your application uses the Qt Mobility libraries, uncomment the following
# lines and add the respective components to the MOBILITY variable.
# CONFIG += mobility
# MOBILITY +=

# Speed up launching on MeeGo/Harmattan when using applauncherd daemon
CONFIG += qdeclarative-boostable \
          meegotouch

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

# Please do not modify the following two lines. Required for deployment.
include(qmlapplicationviewer/qmlapplicationviewer.pri)
qtcAddDeployment()

OTHER_FILES += \
    qtc_packaging/debian_harmattan/rules \
    qtc_packaging/debian_harmattan/README \
    qtc_packaging/debian_harmattan/manifest.aegis \
    qtc_packaging/debian_harmattan/copyright \
    qtc_packaging/debian_harmattan/control \
    qtc_packaging/debian_harmattan/compat \
    qtc_packaging/debian_harmattan/changelog \
    qtc_packaging/debian_fremantle/rules \
    qtc_packaging/debian_fremantle/README \
    qtc_packaging/debian_fremantle/copyright \
    qtc_packaging/debian_fremantle/control \
    qtc_packaging/debian_fremantle/compat \
    qtc_packaging/debian_fremantle/changelog \
    bison/exprparser.y \
    clear.svg \
    mobileCrunchVkb_1.xml \
    qml/mobilecrunch/Pager.qml \
    qml/mobilecrunch/ShadowUp.qml \
    mobileCrunchVkb_2.xml

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

keyboard.path = /opt/mobilecrunch
keyboard.files = mobileCrunchVkb_1.xml \
                 mobileCrunchVkb_2.xml

INSTALLS += keyboard
















