#include <QtGui/QApplication>
#include <QtDeclarative>                                            //IMPORTANT
#include "qmlapplicationviewer.h"
#include "core/evaluator.h"
#include "manager.h"
#include <bb/device/DisplayInfo>
using namespace bb::device;

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    QScopedPointer<QApplication> app(createApplication(argc, argv));
    QScopedPointer<QmlApplicationViewer> viewer(QmlApplicationViewer::create());

    app->setStartDragDistance(27);
    QDeclarativeContext *ctxt = viewer->rootContext();

    manager mn;

    ctxt->setContextProperty("mn",&mn );

    //set device display properties
    QDeclarativePropertyMap* displayProperties = new QDeclarativePropertyMap;
    DisplayInfo display;
    int width = display.pixelSize().width();
    int height = display.pixelSize().height();
    displayProperties->insert("displayWidth", QVariant(width));
    displayProperties->insert("displayHeight", QVariant(height));
    // hardcoded for now
    displayProperties->insert("rotation", QVariant(0));

    ctxt->setContextProperty("screen", displayProperties);

    viewer->setOrientation(QmlApplicationViewer::ScreenOrientationLockPortrait);
    viewer->setMainQmlFile(QLatin1String("qml/mobilecrunch/main.qml"));
    viewer->showExpanded();

    return app->exec();
    //mn.restoreLayouts();
    //return 1;
}
