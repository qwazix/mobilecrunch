#include <QtGui/QApplication>
#include <QtDeclarative>                                            //IMPORTANT
#include "qmlapplicationviewer.h"
#include "core/evaluator.h"
#include "manager.h"

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    QScopedPointer<QApplication> app(createApplication(argc, argv));
    QScopedPointer<QmlApplicationViewer> viewer(QmlApplicationViewer::create());

    manager mn;
    QDeclarativeContext *ctxt = viewer->rootContext();
    ctxt->setContextProperty("mn",&mn );

    viewer->setOrientation(QmlApplicationViewer::ScreenOrientationAuto);
    viewer->setMainQmlFile(QLatin1String("qml/mobilecrunch/main.qml"));
    viewer->showExpanded();

    return app->exec();
    //mn.restoreLayouts();
    //return 1;
}
