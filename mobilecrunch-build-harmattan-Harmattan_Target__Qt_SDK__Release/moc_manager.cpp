/****************************************************************************
** Meta object code from reading C++ file 'manager.h'
**
** Created: Sun May 20 16:17:45 2012
**      by: The Qt Meta Object Compiler version 62 (Qt 4.7.4)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../mobilecrunch/manager.h"
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'manager.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 62
#error "This file was generated using the moc from 4.7.4. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

QT_BEGIN_MOC_NAMESPACE
static const uint qt_meta_data_manager[] = {

 // content:
       5,       // revision
       0,       // classname
       0,    0, // classinfo
      11,   14, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       0,       // signalCount

 // methods: signature, parameters, type, tag, flags
      17,    8,    9,    8, 0x02,
      35,    8,    9,    8, 0x02,
      49,    8,    8,    8, 0x02,
      63,    8,    8,    8, 0x02,
      80,    8,    9,    8, 0x02,
     102,    8,    8,    8, 0x02,
     111,    8,    8,    8, 0x02,
     124,    8,    8,    8, 0x02,
     145,    8,    8,    8, 0x02,
     166,    8,    9,    8, 0x02,
     181,    8,    8,    8, 0x02,

       0        // eod
};

static const char qt_meta_stringdata_manager[] = {
    "manager\0\0QString\0autoCalc(QString)\0"
    "calc(QString)\0loadLayouts()\0"
    "restoreLayouts()\0getFunctions(QString)\0"
    "setABC()\0setNumbers()\0setAngleModeRadian()\0"
    "setAngleModeDegree()\0getAngleMode()\0"
    "setClipboard(QString)\0"
};

const QMetaObject manager::staticMetaObject = {
    { &QObject::staticMetaObject, qt_meta_stringdata_manager,
      qt_meta_data_manager, 0 }
};

#ifdef Q_NO_DATA_RELOCATION
const QMetaObject &manager::getStaticMetaObject() { return staticMetaObject; }
#endif //Q_NO_DATA_RELOCATION

const QMetaObject *manager::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->metaObject : &staticMetaObject;
}

void *manager::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_manager))
        return static_cast<void*>(const_cast< manager*>(this));
    return QObject::qt_metacast(_clname);
}

int manager::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: { QString _r = autoCalc((*reinterpret_cast< const QString(*)>(_a[1])));
            if (_a[0]) *reinterpret_cast< QString*>(_a[0]) = _r; }  break;
        case 1: { QString _r = calc((*reinterpret_cast< const QString(*)>(_a[1])));
            if (_a[0]) *reinterpret_cast< QString*>(_a[0]) = _r; }  break;
        case 2: loadLayouts(); break;
        case 3: restoreLayouts(); break;
        case 4: { QString _r = getFunctions((*reinterpret_cast< QString(*)>(_a[1])));
            if (_a[0]) *reinterpret_cast< QString*>(_a[0]) = _r; }  break;
        case 5: setABC(); break;
        case 6: setNumbers(); break;
        case 7: setAngleModeRadian(); break;
        case 8: setAngleModeDegree(); break;
        case 9: { QString _r = getAngleMode();
            if (_a[0]) *reinterpret_cast< QString*>(_a[0]) = _r; }  break;
        case 10: setClipboard((*reinterpret_cast< QString(*)>(_a[1]))); break;
        default: ;
        }
        _id -= 11;
    }
    return _id;
}
QT_END_MOC_NAMESPACE
