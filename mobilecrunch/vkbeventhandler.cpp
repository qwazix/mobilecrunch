#include "vkbeventhandler.h"
#include "bps/virtualkeyboard.h"
#include <QDebug>

vkbEventHandler* vkbEventHandler::m_BPSEventHandlerInstance = NULL;
static const QString logPrefix("vkbEventHandler::");
vkbEventHandler*
vkbEventHandler::getInstance()
{
  if (!m_BPSEventHandlerInstance) {
    m_BPSEventHandlerInstance = new vkbEventHandler();
  }
  return m_BPSEventHandlerInstance;
}

vkbEventHandler::vkbEventHandler()
{
    qDebug() << logPrefix << "EventHandler(): bps initialize" << bps_initialize();

    const int rc = virtualkeyboard_request_events(0);
    if (rc != BPS_SUCCESS) {
      qDebug() << logPrefix << "EventHandler(): request events failed " << rc;
      return;
    }

    subscribe(virtualkeyboard_get_domain());

}

void vkbEventHandler::event(bps_event_t *event)
{
  // This method listens for events and, based on the category of each event,
  // marshals it.
//  qDebug() << logPrefix
//           << "************************************** EVENT RECEIVED **************************************";

  unsigned int code = bps_event_get_code(event);

  if (code == VIRTUALKEYBOARD_EVENT_VISIBLE) {
      qDebug() << "vkb visible";
      emit keyboardVisible();
  }
  if (code == VIRTUALKEYBOARD_EVENT_HIDDEN){
      qDebug() << "vkb hidden";
      emit keyboardHidden();
  }
}
