#ifndef MANAGER_H
#define MANAGER_H
#include <QObject>                 //IMP
#include <QString>
#include <QStringList>
#include "core/evaluator.h"
#include "core/settings.h"
#include <QDebug>
#include <QClipboard>
#include "vkbeventhandler.h"

class manager : public QObject     //IMP
{
    Q_OBJECT                       //IMP
private:
    Evaluator * evl;
    Settings * settings;
    QClipboard *clipboard;
    vkbEventHandler *eventListener;

signals:
    void vkbHidden();
    void vkbVisible();

private slots:
    void vkbHiddenSlot();
    void vkbVisibleSlot();

public:

    Q_INVOKABLE QString autoCalc(const QString&);
    Q_INVOKABLE QString calc(const QString&);
    Q_INVOKABLE void loadLayouts();
    Q_INVOKABLE void restoreLayouts();
    Q_INVOKABLE QString getFunctions(QString);
    Q_INVOKABLE void setAngleModeRadian();
    Q_INVOKABLE void setAngleModeDegree();
    Q_INVOKABLE QString getAngleMode();
    Q_INVOKABLE void setClipboard(QString);
    Q_INVOKABLE QString getClipboard();
    Q_INVOKABLE void hideKeyboard();
    Q_INVOKABLE void changeKeyboardType(int mode);
    Q_INVOKABLE int getKeyboardHeight();

    manager();
};

#endif // MANAGER_H
