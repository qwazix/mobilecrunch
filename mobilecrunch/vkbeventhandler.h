#ifndef VKBEVENTHANDLER_H
#define VKBEVENTHANDLER_H

#include <QObject>
#include <bb/AbstractBpsEventHandler>

#include <bbmsp/bbmsp.h>
#include <bbmsp/bbmsp_events.h>

class vkbEventHandler : public QObject, public bb::AbstractBpsEventHandler
{
    Q_OBJECT
signals:
    void keyboardHidden();
    void keyboardVisible();

public:
    void event(bps_event_t *event);
    static vkbEventHandler* getInstance();
//    vkbEventHandler();

private:
  vkbEventHandler();
  virtual ~vkbEventHandler(){}

private:
  static vkbEventHandler* m_BPSEventHandlerInstance;
};



#endif // VKBEVENTHANDLER_H
