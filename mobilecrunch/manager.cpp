#include "manager.h"
#include <QFile>
#include <QDir>
#include <QApplication>
#include "core/functions.h"
#include "core/constants.h"

//save the active keyboard
manager::manager()
{
    evl = Evaluator::instance();
    settings = Settings::instance();
    clipboard = QApplication::clipboard();
}

QString manager::autoCalc(const QString &input){

    const QString str = evl->autoFix( input );
    if ( str.isEmpty() )
        return QString("");

    // very short (just one token) and still no calculation, then skip
    //if ( ! d->ansAvailable ) {
//        const Tokens tokens = evl->scan( input );
//        if ( tokens.count() < 2 )
//            return "";
    //}

    // too short even after autofix ? do not bother either...
    const Tokens tokens = evl->scan( str );
    if ( tokens.count() < 2 )
        return QString("");

    // strip off assignment operator, e.g. "x=1+2" becomes "1+2" only
    // the reason is that we want only to evaluate (on the fly) the expression,
    // not to update (put the result in) the variable
    //if( tokens.count() > 2 ) // reftk
    //if( tokens.at(0).isIdentifier() )
    //if( tokens.at(1).asOperator() == Token::Equal )
    //  str.remove( 0, tokens.at(1).pos()+1 );

    // same reason as above, do not update "ans"
    evl->setExpression( str );
    const HNumber num = evl->evalNoAssign();

    return QString(HMath::format(num,'g',4));
}

QString manager::calc(const QString &input){
    const QString str = evl->autoFix( input );
    evl->setExpression( str );
    const HNumber num = evl->eval();
    return QString(HMath::format(num,'g',4));
}


void manager::loadLayouts()
{


}


void manager::restoreLayouts()
{

}

QString manager::getFunctions(QString needle){
    QStringList functionNames = Functions::instance()->names();
    QString str = "[";
     for (int k = 0; k < functionNames.count(); ++k)
     {
         Function *f = Functions::instance()->function(functionNames.at(k));
         if (!f)
             continue;

         if (needle=="" || f->name().toLower().contains(needle.toLower()) || f->identifier().toLower().contains(needle.toLower()))
            str += "{ val:'" + f->identifier()+ "' , name: '" + f->name() + "' , func: true},";

     }
     QList<Constant> constantNames = Constants::instance()->list();
     for (int k = 0; k < constantNames.count(); ++k){
         //QString name = ;
         if (needle=="" || constantNames.at(k).value.contains(needle, Qt::CaseInsensitive) || constantNames.at(k).name.contains(needle, Qt::CaseInsensitive))
            str += "{ val:'" +constantNames.at(k).value + "' , name: \"" + constantNames.at(k).name +"\", func: false},";
         //if (k==2) qDebug()<<name.replace("'","\\\'");
     }

     str += "]";
     return str;

    // return Functions::instance()->names();
}

void manager::setABC()
{
#if !defined(Q_WS_SIMULATOR)

    //load gconf to memory
    QString binFilename(QString("libmeego-keyboard.so"));
    QStringList currentLayout;
    currentLayout.append(binFilename);
    currentLayout.append("en_us.xml");
#endif
}

void manager::setNumbers()
{
#if !defined(Q_WS_SIMULATOR)

    //load gconf to memory
    QString binFilename(QString("libmeego-keyboard.so"));
    QStringList currentLayout;
    currentLayout.append(binFilename);
    currentLayout.append("mobileCrunchVkb_1.xml");
#endif
}

void manager::setAngleModeRadian()
{
    if ( settings->angleUnit == 'r' )
        return;
    qDebug()<<settings->angleUnit;
    settings->angleUnit = 'r';
    settings->save();

}

void manager::setAngleModeDegree()
{

    if ( settings->angleUnit == 'd' )
        return;
//     qDebug()<<settings->angleUnit;
     settings->angleUnit = 'd';
     settings->save();
}

QString manager::getAngleMode()
{
    settings->load();
    qDebug()<<settings->angleUnit;
    return QString(settings->angleUnit);
}


void manager::setClipboard(QString text){
        clipboard->setText(text, QClipboard::Clipboard);
        clipboard->setText(text, QClipboard::Selection);
    }


