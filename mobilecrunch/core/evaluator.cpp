// This file is part of the SpeedCrunch project
// Copyright (C) 2004 Ariya Hidayat <ariya@kde.org>
// Copyright (C) 2005, 2006 Johan Thelin <e8johan@gmail.com>
// Copyright (C) 2007, 2008, 2009, 2010 Helder Correia <helder.pereira.correia@gmail.com>
// Copyright (C) 2009 Wolf Lammen <ookami1@gmx.de>
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; see the file COPYING.  If not, write to
// the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
// Boston, MA 02110-1301, USA.

#include "core/evaluator.h"

#include "core/functions.h"
#ifdef _BISON
#include "bison/bisonparser.cpp"
#endif // _BISON

#include <QtCore/QCoreApplication>
#include <QtCore/QMap>
#include <QtCore/QStack>

//#define EVALUATOR_DEBUG
#ifdef EVALUATOR_DEBUG
#include <QtCore/QFile>
#include <QtCore/QTextStream>

QTextStream & operator<<( QTextStream & s, HNumber num )
{
    char * str = HMath::format( num, 'f' );
    s << str;
    free( str );
    return s;
}
#endif // EVALUATOR_DEBUG

static Evaluator * s_evaluatorInstance = 0;

static void s_deleteEvaluator()
{
    delete s_evaluatorInstance;
}

struct Opcode
{
    enum { Nop = 0, Load, Ref, Function, Add, Sub, Neg, Mul, Div,
           Pow, Pow0, Pow1, Pow2, Pow3, Pow4, Pow5, Pow6, Pow7, Pow8, Pow9,
           Fact, Modulo, IntDiv, LSh, RSh, BAnd, BOr };

    unsigned type;
    unsigned index;

    Opcode() : type( Nop ), index( 0 ) {};
    Opcode( unsigned t ) : type(t), index( 0 ) {};
    Opcode( unsigned t, unsigned i ): type( t ), index( i ) {};
};

struct Evaluator::Private
{
    bool dirty;
    QString error;
    QString expression;
    bool valid;

    QString assignId;
    QVector<Opcode> codes;
    QVector<HNumber> constants;
    QStringList identifiers;
    QMap<QString,Variable> variables;
    const HNumber & checkOperatorResult(const HNumber &);
};

const HNumber& Evaluator::Private::checkOperatorResult( const HNumber & n )
{
    switch ( n.error() )
    {
        case NoOperand:
            error = Evaluator::tr("cannot operate on a NaN");
            break;
        case Underflow:
            error = Evaluator::tr("underflow - tiny result is out of SpeedCrunch's number range");
            break;
        case Overflow:
            error = Evaluator::tr("overflow - huge result is out of SpeedCrunch's number range");
            break;
        case ZeroDivide:
            error = Evaluator::tr("division by zero");
            break;
        case OutOfLogicRange:
            error = Evaluator::tr("overflow - logic result exceeds maximum of 256 bits");
            break;
        case OutOfIntegerRange:
            error = Evaluator::tr("overflow - integer result exceeds maximum limit for integers");
            break;
        case TooExpensive:
            error = Evaluator::tr("too time consuming computation was rejected");
            break;
        default:;
    }
    return n;
}


class TokenStack : public QVector<Token>
{
public:
    TokenStack();

    bool isEmpty() const;
    unsigned itemCount() const;
    Token pop();
    void push( const Token & token );
    const Token & top();
    const Token & top( unsigned index );

private:
    void ensureSpace();
    int topIndex;
};

const Token Token::null;

// helper function: return operator of given token text
// e.g. "*" yields Operator::Asterisk, and so on
static Token::Op matchOperator( const QString & text )
{
    Token::Op result = Token::InvalidOp;

    if ( text.length() == 1 ) {
        QChar p = text.at( 0 );
        switch( p.unicode() ) {
            case '+' : result = Token::Plus; break;
            case '-' : result = Token::Minus; break;
            case '*' : result = Token::Asterisk; break;
            case '/' : result = Token::Slash; break;
            case '^' : result = Token::Caret; break;
            case ';' : result = Token::Semicolon; break;
            case '(' : result = Token::LeftPar; break;
            case ')' : result = Token::RightPar; break;
            case '%' : result = Token::Percent; break;
            case '!' : result = Token::Exclamation; break;
            case '=' : result = Token::Equal; break;
            case '\\': result = Token::Backslash; break;
            case '&' : result = Token::Ampersand; break;
            case '|' : result = Token::Pipe; break;

            case 0x2070: result = Token::Super0; break; // ⁰
            case 0x00B9: result = Token::Super1; break; // ¹
            case 0x00B2: result = Token::Super2; break; // ²
            case 0x00B3: result = Token::Super3; break; // ³
            case 0x2074: result = Token::Super4; break; // ⁴
            case 0x2075: result = Token::Super5; break; // ⁵
            case 0x2076: result = Token::Super6; break; // ⁶
            case 0x2077: result = Token::Super7; break; // ⁷
            case 0x2078: result = Token::Super8; break; // ⁸
            case 0x2079: result = Token::Super9; break; // ⁹

            default  : result = Token::InvalidOp;
        }
    } else if ( text.length() == 2 ) {
        if ( text == "**" )
            result = Token::Caret;
        else if( text == "<<" )
          result = Token::LeftShift;
        else if( text == ">>" )
          result = Token::RightShift;
    }
#if 0
    else if ( text.length() == 3 ) {
        if (text == "mod")
            result = Token::Modulo;
    }
#endif

   return result;
}

// helper function: give operator precedence
// e.g. "+" is 1 while "*" is 3
static int opPrecedence( Token::Op op )
{
    int prec;
    switch( op ) {
        case Token::Exclamation : prec = 8; break;
        case Token::Percent     : prec = 8; break;
        case Token::Super0      :
        case Token::Super1      :
        case Token::Super2      :
        case Token::Super3      :
        case Token::Super4      :
        case Token::Super5      :
        case Token::Super6      :
        case Token::Super7      :
        case Token::Super8      :
        case Token::Super9      :
        case Token::Caret       : prec = 7; break;
        case Token::Asterisk    : prec = 5; break;
        case Token::Slash       : prec = 6; break;
        case Token::Modulo      :
        case Token::Backslash   : prec = 6; break;
        case Token::Plus        :
        case Token::Minus       : prec = 3; break;
        case Token::LeftShift   :
        case Token::RightShift  : prec = 2; break;
        case Token::Ampersand   : prec = 1; break;
        case Token::Pipe        : prec = 0; break;
        case Token::RightPar    :
        case Token::Semicolon   : prec = -1; break;
        case Token::LeftPar     : prec = -2; break;
        default                 : prec = -2; break;
    }
    return prec;
}

Token::Token( Type type, const QString& text, int pos )
{
    m_type = type;
    m_text = text;
    m_pos = pos;
}

Token::Token( const Token& token )
{
    m_type = token.m_type;
    m_text = token.m_text;
    m_pos  = token.m_pos;
}

Token & Token::operator=( const Token & token )
{
    m_type = token.m_type;
    m_text = token.m_text;
    m_pos = token.m_pos;
    return *this;
}

HNumber Token::asNumber() const
{
    QString text = m_text;
    text.replace( ",", "." ); // issue 151
    return isNumber() ? HNumber( (const char *)text.toLatin1() ) : HNumber( 0 );
}

Token::Op Token::asOperator() const
{
    return isOperator() ? matchOperator( m_text ) : InvalidOp;
}

QString Token::description() const
{
    QString desc;

    switch ( m_type ) {
        case stxNumber     : desc = "Number"; break;
        case stxIdentifier : desc = "Identifier"; break;
        case stxOpenPar    : //refty
        case stxClosePar   :
        case stxSep        :
        case stxOperator   : desc = "Operator"; break;
        default            : desc = "Unknown"; break;
    }

    while ( desc.length() < 10 )
        desc.prepend( ' ' );
    desc.prepend( "  " );
    desc.prepend( QString::number( m_pos ) );
    desc.append( " : " ).append( m_text );

    return desc;
}

TokenStack::TokenStack(): QVector<Token>()
{
    topIndex = 0;
    ensureSpace();
}

bool TokenStack::isEmpty() const
{
    return topIndex == 0;
}

unsigned TokenStack::itemCount() const
{
    return topIndex;
}

void TokenStack::push( const Token& token )
{
    ensureSpace();
    (*this)[topIndex++] = token;
}

Token TokenStack::pop()
{
    return topIndex > 0 ? Token( at(--topIndex) ) : Token();
}

const Token& TokenStack::top()
{
    return top( 0 );
}

const Token& TokenStack::top( unsigned index )
{
    return (topIndex > (int)index) ? at( topIndex - index - 1 ) : Token::null;
}

void TokenStack::ensureSpace()
{
    int length = size();
    while ( topIndex >= length ) {
        length += 10;
        resize( length );
    }
}

// helper function: return true for valid identifier character
static bool isIdentifier( QChar ch )
{
    return ch.unicode() == '_' || ch.unicode() == '$' || ch.isLetter();
}

Evaluator * Evaluator::instance()
{
    if ( ! s_evaluatorInstance ) {
        s_evaluatorInstance = new Evaluator;
        qAddPostRoutine( s_deleteEvaluator );
    }
    return s_evaluatorInstance;
}

Evaluator::Evaluator()
    : d( new Evaluator::Private )
{
    clear();

#ifdef _BISON
    QStringList script;
    script << "\\escape \\(\\\"@\\\"\\)"
           << "@def @(@\"\"@\"@;@\"\"@\"@;@\"\"@\"@)"
           << "@def @(\"(\"@;\"(\"@;\")\"@)"
           << "@def (\";\"@;\";\")"
           << "@def (\"def\";\"def\")"

           << "def(\"escape\";\"esc\")"
           << "esc \"\\\""
           << "def(\",\";\"0,\")"
           << "\\undef (\"esc\"; 0,00)"
           << "\\def (\".\";\".\")"

           << "\\def (\".\";\"0.\")"
           << "\\def (\"e\";\"0e\")"
           << "\\def (\"p\";\"0p\")"
           << "\\def (\"x\";\"0x\")"
           << "\\def (\"xs\";\"0xs\")"

           << "\\sin 0.3e1"
           << "0x2Fp2"
           << "0xsF0"
           << "\\def (\"posscale\"; \"1+\")"
           << "\\def (\"negscale\"; \"1-\")"

           << "2e-1"
           << "\\def (\"-\";\"-\")"
           << "-1"
           << "\\overload (\"add\";\"-\")"
           << "-1-2"

           << "\\def (\"!\";\"!\")"
           << "-1!"
           << "\\def (\"pi\";\"pi\")"
           << "\\def (\"sin\";\"sin\")"
           << "sin pi";

    SglExprLex::self().run( script );
#endif
}

Evaluator::~Evaluator()
{
}

// Sets a new expression
// note that both the real lex and parse processes will happen later on
// when needed (i.e. "lazy parse"), for example during evaluation.
void Evaluator::setExpression( const QString& expr )
{
#ifdef _BISON
    SglExprLex::self().setExpression(expr);
#endif

    d->expression = expr;
    d->dirty = true;
    d->valid = false;
    d->error = QString();
}

QString Evaluator::expression() const
{
    return d->expression;
}

// Returns the validity
// note: empty expression is always invalid.
bool Evaluator::isValid() const
{
    if ( d->dirty ) {
        Tokens tokens = scan( d->expression );
        if ( ! tokens.valid() )
            compile( tokens );
        else
            d->valid = false;
    }
    return d->valid;
}

void Evaluator::clear()
{
    d->expression = QString();
    d->dirty = true;
    d->valid = false;
    d->error = QString();
    d->constants.clear();
    d->codes.clear();
    d->assignId = QString();
    clearVariables();
}

QString Evaluator::error() const
{
    return d->error;
}

// Returns list of token for the expression.
// this triggers again the lexical analysis step. it is however preferable
// (even when there's small performance penalty) because otherwise we need to
// store parsed tokens all the time which serves no good purpose.
Tokens Evaluator::tokens() const
{
    return scan( d->expression );
}

Tokens Evaluator::scan( const QString& expr ) const
{
    // result
    Tokens tokens;

    // parsing state
    enum { Start, Finish, Bad, InNumber, InHexa, InOctal, InBinary, InDecimal, InExpIndicator,
           InExponent, InIdentifier } state;

    // initialize variables
    state = Start;
    int i = 0;
    QString ex = expr;
    QString tokenText;
    int tokenStart = 0;
    Token::Type type;

    // force a terminator
    ex.append( QChar() );

    // main loop
    while ( state != Bad && state != Finish && i < ex.length() )
    {
        QChar ch = ex.at( i );

        switch ( state )
        {
            case Start:
                tokenStart = i;

                // skip any whitespaces
                if ( ch.isSpace() )
                    ++i;
                else if ( ch.isDigit() ) // check for number
                    state = InNumber;
                else if ( ch == '#' ) { // simple hexadec notation
                    tokenText.append( "0x" );
                    state = InHexa;
                    ++i;
                } else if ( ch == '.' || ch == ',' ) { // radix char ?
                    tokenText.append( ex.at(i++) );
                    state = InDecimal;
                } else if ( ch.isNull() ) // terminator character
                    state = Finish;
                else { // look for operator match
                    int op;
                    QString s;
#if 0
                    // check for three-chars operator
                    s.append( ch ).append( ex.at(i+1) ).append( ex.at(i+2) );
                    op = matchOperator( s );

                    // check for two-chars operator
                    if ( op == Token::InvalidOp )
#endif
                    {
                        s = QString( ch ).append( ex.at(i+1) );
                        op = matchOperator( s );
                    }

                    // check for one-char operator
                    if ( op == Token::InvalidOp ) {
                        s = QString( ch );
                        op = matchOperator( s );
                    }

                    // any matched operator ?
                    if ( op != Token::InvalidOp ) {
                        switch( op ) { //refty
                            case Token::LeftPar: type = Token::stxOpenPar; break;
                            case Token::RightPar: type = Token::stxClosePar; break;
                            case Token::Semicolon: type = Token::stxSep; break;
                            default: type = Token::stxOperator;
                        }
                        int len = s.length();
                        i += len;
                        tokens.append( Token(type, s.left(len), tokenStart) );
                    }
                    else
                        state = Bad;
                }

                // beginning with unknown alphanumeric ?
                // could be identifier, or function...
                if ( state == Bad && isIdentifier(ch) )
                    state = InIdentifier;
                break;

            case InIdentifier:
                // consume as long as alpha, dollar sign, underscore, or digit
                if ( isIdentifier(ch) || ch.isDigit() )
                    tokenText.append( ex.at(i++) );
                // we're done with identifier
                else {
                    tokens.append( Token(Token::stxIdentifier, tokenText, tokenStart) );
                    tokenStart = i;
                    tokenText = "";
                    state = Start;
                }
                break;

            case InNumber:
                if ( ch.isDigit() ) // consume as long as it's a digit
                    tokenText.append( ex.at(i++) );
                else if ( ch == '.' || ch == ',' ) { // convert to '.'
                    tokenText.append( '.' );
                    ++i;
                    state = InDecimal;
                }
                else if ( ch.toUpper() == 'E' ) { // exponent ?
                    tokenText.append( 'E' );
                    ++i;
                    state = InExpIndicator;
                } else if ( ch.toUpper() == 'X' && tokenText == "0" ) { // normal hexadec notation
                    tokenText.append( 'x' );
                    ++i;
                    state = InHexa;
                } else if ( ch.toUpper() == 'B' && tokenText == "0" ) { // binary notation
                    tokenText.append( 'b' );
                    ++i;
                    state = InBinary;
                } else if ( ch.toUpper() == 'O' && tokenText == "0" ) { // octal notation
                    tokenText.append( 'o' ); i++; state = InOctal;
                } else if ( ch.toUpper() == 'D' && tokenText == "0" ) { // explicit dec notation
                    tokenText = ""; // we also need to get rid of the leading zero
                    ++i;
                } else { // we're done with integer number
                    tokens.append( Token(Token::stxNumber, tokenText, tokenStart) );
                    tokenText = "";
                    state = Start;
                }
                break;

            case InHexa:
                if ( ch.isDigit() || (ch >= 'A' && ch < 'G') || (ch >= 'a' && ch < 'g') )
                    tokenText.append( ex.at(i++).toUpper() );
                else { // we're done with hexa number
                    tokens.append( Token(Token::stxNumber, tokenText, tokenStart) );
                    tokenText = "";
                    state = Start;
                }
                break;

            case InBinary:
                if ( ch == '0' || ch == '1' ) // very strict rule ;)
                    tokenText.append( ex.at(i++) );
                else { // we're done with binary number
                    tokens.append( Token(Token::stxNumber, tokenText, tokenStart) );
                    tokenText = "";
                    state = Start;
                }
                break;

            case InOctal:
                if ( ch >= '0' && ch < '8' ) // octal has only 8 digits, 8 & 9 are invalid
                    tokenText.append( ex.at(i++) );
                else { // we're done with octal number
                    tokens.append( Token(Token::stxNumber, tokenText, tokenStart) );
                    tokenText = ""; state = Start;
                }
                break;

            case InDecimal:
                if ( ch.isDigit() ) // consume as long as it's digit
                    tokenText.append( ex.at(i++) );
                else if ( ch.toUpper() == 'E' ) { // exponent ?
                    tokenText.append( 'E' );
                    ++i;
                    state = InExpIndicator;
                } else { // we're done with floating-point number
                    tokens.append( Token(Token::stxNumber, tokenText, tokenStart) );
                    tokenText = "";
                    state = Start;
                };
                break;

            case InExpIndicator:
                if ( ch == '+' || ch == '-' ) // possible + or - right after E
                    tokenText.append( ex.at(i++) );
                else if ( ch.isDigit() ) // consume as long as it's a digit
                    state = InExponent;
                else // invalid thing here
                    state = Bad;
                break;

            case InExponent:
                if ( ch.isDigit() ) // consume as long as it's a digit
                    tokenText.append( ex.at(i++) );
                else { // we're done with floating-point number
                    tokens.append( Token(Token::stxNumber, tokenText, tokenStart) );
                    tokenText = "";
                    state = Start;
                };
                break;

            case Bad: // bad bad bad
                tokens.setValid( false );
                break;

            default:
                break;
        };
    }
    if (state == Bad) {
        // invalidating here, too, because:
        // usually when we set state to Bad, the case Bad won't be run
        tokens.setValid(false);
    }

    return tokens;
}

void Evaluator::compile( const Tokens & tokens ) const
{
#ifdef EVALUATOR_DEBUG
    QFile debugFile( "eval.log" );
    debugFile.open( QIODevice::WriteOnly );
    QTextStream dbg( &debugFile );
#endif

    // initialize variables
    d->dirty = false;
    d->valid = false;
    d->codes.clear();
    d->constants.clear();
    d->identifiers.clear();
    d->error = QString();

    // sanity check
    if ( tokens.count() == 0 )
        return;

    TokenStack syntaxStack;
    QStack<int> argStack;
    unsigned argCount = 1;

    for ( int i = 0; i <= tokens.count(); ++i ) {
        // helper token: InvalidOp is end-of-expression
        Token token = (i < tokens.count()) ? tokens.at( i ) : Token( Token::stxOperator );
        Token::Type tokenType = token.type();
        if ( tokenType >= Token::stxOperator )
            tokenType = Token::stxOperator;

#ifdef EVALUATOR_DEBUG
        dbg << "\n";
        dbg << "Token: " << token.description() << "\n";
#endif

        // unknown token is invalid
        if ( tokenType == Token::stxUnknown )
            break;

        // for constants, push immediately to stack
        // generate code to load from a constant
        if ( tokenType == Token::stxNumber ) {
            syntaxStack.push( token );
            d->constants.append( token.asNumber() );
            d->codes.append( Opcode(Opcode::Load, d->constants.count() - 1) );
#ifdef EVALUATOR_DEBUG
            dbg << "  Push " << token.asNumber() << " to constant pools" << "\n";
#endif
        }

        // for identifier, push immediately to stack
        // generate code to load from reference
        if ( tokenType == Token::stxIdentifier ) {
            syntaxStack.push( token );
            d->identifiers.append( token.text() );
            d->codes.append( Opcode(Opcode::Ref, d->identifiers.count() - 1) );
#ifdef EVALUATOR_DEBUG
            dbg << "  Push " << token.text() << " to identifier pools" << "\n";
#endif
        }

        // special case for percentage
        if ( tokenType == Token::stxOperator && token.asOperator() == Token::Percent
             && syntaxStack.itemCount() >= 1 && ! syntaxStack.top().isOperator() )
        {
            d->constants.append( HNumber("0.01") );
            d->codes.append( Opcode(Opcode::Load, d->constants.count() - 1) );
            d->codes.append( Opcode(Opcode::Mul) );
#ifdef EVALUATOR_DEBUG
            dbg << "  Handling percentage" << "\n";
#endif
        }

        // for any other operator, try to apply all parsing rules
        if ( tokenType == Token::stxOperator && token.asOperator() != Token::Percent ) {
#ifdef EVALUATOR_DEBUG
            dbg << "  Checking rules..." << "\n";
#endif
            // repeat until no more rule applies
            bool argHandled = false;
            while ( true ) {
                bool ruleFound = false;

                // rule for function last argument:
                //   id ( arg ) -> arg
                if ( ! ruleFound && syntaxStack.itemCount() >= 4 ) {
                    Token par2 = syntaxStack.top();
                    Token arg = syntaxStack.top( 1 );
                    Token par1 = syntaxStack.top( 2 );
                    Token id = syntaxStack.top( 3 );
                    if ( par2.asOperator() == Token::RightPar && ! arg.isOperator()
                         && par1.asOperator() == Token::LeftPar && id.isIdentifier() )
                    {
                        ruleFound = true;
                        syntaxStack.pop();
                        syntaxStack.pop();
                        syntaxStack.pop();
                        syntaxStack.pop();
                        syntaxStack.push( arg );
                        d->codes.append( Opcode(Opcode::Function, argCount) );
#ifdef EVALUATOR_DEBUG
                        dbg << "    Rule for function last argument " << argCount << " \n";
#endif
                        argCount = argStack.empty() ? 0 : argStack.pop();
                    }
                }

                // are we entering a function ?
                // if token is operator, and stack already has: id ( arg
                if ( ! ruleFound && ! argHandled && tokenType == Token::stxOperator
                     && syntaxStack.itemCount() >= 3 )
                {
                    Token arg = syntaxStack.top();
                    Token par = syntaxStack.top( 1 );
                    Token id = syntaxStack.top( 2 );
                    if ( ! arg.isOperator() && par.asOperator() == Token::LeftPar
                         && id.isIdentifier() )
                    {
                        ruleFound = true;
                        argStack.push( argCount );
                        argCount = 1;
#ifdef EVALUATOR_DEBUG
                        dbg << "  Entering function " << argCount << " \n";
#endif
                        break;
                    }
                }

                // rule for postfix operators
                if ( ! ruleFound && syntaxStack.itemCount() >= 2 ) {
                    Token postfix = syntaxStack.top();
                    Token y = syntaxStack.top( 1 );
                    if ( postfix.isOperator() && ! y.isOperator() )
                        switch ( postfix.asOperator() ) {
                            case Token::Exclamation:
                                ruleFound = true;
                                syntaxStack.pop();
                                syntaxStack.pop();
                                syntaxStack.push(y);
                                d->codes.append( Opcode(Opcode::Fact) );
                                break;
                            case Token::Super0:
                                ruleFound = true;
                                syntaxStack.pop();
                                syntaxStack.pop();
                                syntaxStack.push(y);
                                d->codes.append( Opcode(Opcode::Pow0) );
                                break;
                            case Token::Super1:
                                ruleFound = true;
                                syntaxStack.pop();
                                syntaxStack.pop();
                                syntaxStack.push(y);
                                d->codes.append( Opcode(Opcode::Pow1) );
                                break;
                            case Token::Super2:
                                ruleFound = true;
                                syntaxStack.pop();
                                syntaxStack.pop();
                                syntaxStack.push(y);
                                d->codes.append( Opcode(Opcode::Pow2) );
                                break;
                            case Token::Super3:
                                ruleFound = true;
                                syntaxStack.pop();
                                syntaxStack.pop();
                                syntaxStack.push(y);
                                d->codes.append( Opcode(Opcode::Pow3) );
                                break;
                            case Token::Super4:
                                ruleFound = true;
                                syntaxStack.pop();
                                syntaxStack.pop();
                                syntaxStack.push(y);
                                d->codes.append( Opcode(Opcode::Pow4) );
                                break;
                            case Token::Super5:
                                ruleFound = true;
                                syntaxStack.pop();
                                syntaxStack.pop();
                                syntaxStack.push(y);
                                d->codes.append( Opcode(Opcode::Pow5) );
                                break;
                            case Token::Super6:
                                ruleFound = true;
                                syntaxStack.pop();
                                syntaxStack.pop();
                                syntaxStack.push(y);
                                d->codes.append( Opcode(Opcode::Pow6) );
                                break;
                            case Token::Super7:
                                ruleFound = true;
                                syntaxStack.pop();
                                syntaxStack.pop();
                                syntaxStack.push(y);
                                d->codes.append( Opcode(Opcode::Pow7) );
                                break;
                            case Token::Super8:
                                ruleFound = true;
                                syntaxStack.pop();
                                syntaxStack.pop();
                                syntaxStack.push(y);
                                d->codes.append( Opcode(Opcode::Pow8) );
                                break;
                            case Token::Super9:
                                ruleFound = true;
                                syntaxStack.pop();
                                syntaxStack.pop();
                                syntaxStack.push(y);
                                d->codes.append( Opcode(Opcode::Pow9) );
                                break;
                            default:;
#ifdef EVALUATOR_DEBUG
                                dbg << "    Rule for postfix operator" << "\n";
#endif
                        }
                }

                // rule for parenthesis:  ( Y ) -> Y
                if ( !ruleFound && syntaxStack.itemCount() >= 3 ) {
                    Token right = syntaxStack.top();
                    Token y = syntaxStack.top( 1 );
                    Token left = syntaxStack.top( 2 );
                    if ( right.isOperator() && ! y.isOperator() && left.isOperator()
                         && right.asOperator() == Token::RightPar
                         && left.asOperator() == Token::LeftPar )
                    {
                        ruleFound = true;
                        syntaxStack.pop();
                        syntaxStack.pop();
                        syntaxStack.pop();
                        syntaxStack.push( y );
#ifdef EVALUATOR_DEBUG
                        dbg << "    Rule for (Y) -> Y" << "\n";
#endif
                    }
                }

                // rule for simplified syntax for function e.g. "sin pi" or "cos 1.2"
                // i.e no need for parentheses like "sin(pi)" or "cos(1.2)"
                if ( ! ruleFound && syntaxStack.itemCount() >= 2 ) {
                    Token arg = syntaxStack.top();
                    Token id = syntaxStack.top( 1 );
                    if ( ! arg.isOperator() && id.isIdentifier()
                         && Functions::instance()->function(id.text()) )
                    {
                        ruleFound = true;
                        d->codes.append( Opcode(Opcode::Function, 1) );
                        syntaxStack.pop();
                        syntaxStack.pop();
                        syntaxStack.push( arg );
#ifdef EVALUATOR_DEBUG
                        dbg << "    Rule for simplified function syntax" << "\n";
#endif
                    }
                }

                // rule for unary operator in simplified function syntax
                // this handles case like "sin -90"
                if ( ! ruleFound && syntaxStack.itemCount() >= 3 ) {
                    Token x = syntaxStack.top();
                    Token op = syntaxStack.top( 1 );
                    Token id = syntaxStack.top( 2 );
                    if ( ! x.isOperator() && op.isOperator() && id.isIdentifier()
                         && Functions::instance()->function(id.text())
                         && (op.asOperator() == Token::Plus || op.asOperator() == Token::Minus) )
                    {
                        ruleFound = true;
                        syntaxStack.pop();
                        syntaxStack.pop();
                        syntaxStack.push( x );
                        if ( op.asOperator() == Token::Minus )
                            d->codes.append( Opcode(Opcode::Neg) );
#ifdef EVALUATOR_DEBUG
                        dbg << "    Rule for unary operator in simplified function syntax" << "\n";
#endif
                    }
                }

#if 0
                // rule for unary postfix operator in simplified function syntax
                // this handles case like "sin 90!"
                if ( ! ruleFound && syntaxStack.itemCount() >= 3 ) {
                    Token op = syntaxStack.top();
                    Token x = syntaxStack.top( 1 );
                    Token id = syntaxStack.top( 2 );
                    if ( id.isIdentifier() && d->functions->function(id.text()) ) {
                        if ( ! x.isOperator() && op.isOperator() &&
                             op.asOperator() == Token::Exclamation )
                        {
                            ruleFound = true;
                            syntaxStack.pop();
                            syntaxStack.pop();
                            syntaxStack.push( x );
                            d->codes.append( Opcode( Opcode::Fact ) );
#ifdef EVALUATOR_DEBUG
                            dbg << "    Rule for unary operator in simplified function syntax"
                                << "\n";
#endif
                        }
                    }
                }
#endif

                // rule for function arguments, if token is , or )
                // id ( arg1 ; arg2 -> id ( arg
                if ( ! ruleFound && syntaxStack.itemCount() >= 5
                     && (token.asOperator() == Token::RightPar
                         || token.asOperator() == Token::Semicolon) )
                {
                    Token arg2 = syntaxStack.top();
                    Token sep = syntaxStack.top( 1 );
                    Token arg1 = syntaxStack.top( 2 );
                    Token par = syntaxStack.top( 3 );
                    Token id = syntaxStack.top( 4 );
                    if ( ! arg2.isOperator() && sep.asOperator() == Token::Semicolon
                         && ! arg1.isOperator()
                         && par.asOperator() == Token::LeftPar && id.isIdentifier() )
                    {
                        ruleFound = true;
                        argHandled = true;
                        syntaxStack.pop();
                        syntaxStack.pop();
                        ++argCount;
#ifdef EVALUATOR_DEBUG
                        dbg << "    Rule for function argument " << argCount << " \n";
#endif
                    }
                }

                // rule for function call with parentheses, but without argument
                // e.g. "2*PI()"
                if ( ! ruleFound && syntaxStack.itemCount() >= 3 ) {
                    Token par2 = syntaxStack.top();
                    Token par1 = syntaxStack.top( 1 );
                    Token id = syntaxStack.top( 2 );
                    if ( par2.asOperator() == Token::RightPar
                         && par1.asOperator() == Token::LeftPar && id.isIdentifier() )
                    {
                        ruleFound = true;
                        syntaxStack.pop();
                        syntaxStack.pop();
                        syntaxStack.pop();
                        syntaxStack.push( Token(Token::stxNumber) );
                        d->codes.append( Opcode(Opcode::Function, 0) );
#ifdef EVALUATOR_DEBUG
                        dbg << "    Rule for function call with parentheses, but without argument"
                            << "\n";
#endif
                    }
                }

                // rule for binary operator:  A (op) B -> A
                // conditions: precedence of op >= precedence of token
                // action: push (op) to result
                // e.g. "A * B" becomes "A" if token is operator "+"
                // exception: for caret (power operator), if op is another caret
                // then the rule doesn't apply, e.g. "2^3^2" is evaluated as "2^(3^2)"
                if ( ! ruleFound && syntaxStack.itemCount() >= 3 ) {
                    Token b = syntaxStack.top();
                    Token op = syntaxStack.top( 1 );
                    Token a = syntaxStack.top( 2 );
                    if ( ! a.isOperator() && ! b.isOperator() && op.isOperator()
                         && token.asOperator() != Token::LeftPar
                         && token.asOperator() != Token::Caret
                         && opPrecedence(op.asOperator()) >= opPrecedence(token.asOperator()) )
                    {
                        ruleFound = true;
                        syntaxStack.pop();
                        syntaxStack.pop();
                        syntaxStack.pop();
                        syntaxStack.push( b );
                        switch ( op.asOperator() ) {
                            // simple binary operations
                            case Token::Plus:      d->codes.append( Opcode::Add ); break;
                            case Token::Minus:     d->codes.append( Opcode::Sub ); break;
                            case Token::Asterisk:  d->codes.append( Opcode::Mul ); break;
                            case Token::Slash:     d->codes.append( Opcode::Div ); break;
                            case Token::Caret:     d->codes.append( Opcode::Pow ); break;
                            case Token::Super0:    d->codes.append( Opcode::Pow0 ); break;
                            case Token::Super1:    d->codes.append( Opcode::Pow1 ); break;
                            case Token::Super2:    d->codes.append( Opcode::Pow2 ); break;
                            case Token::Super3:    d->codes.append( Opcode::Pow3 ); break;
                            case Token::Super4:    d->codes.append( Opcode::Pow4 ); break;
                            case Token::Super5:    d->codes.append( Opcode::Pow5 ); break;
                            case Token::Super6:    d->codes.append( Opcode::Pow6 ); break;
                            case Token::Super7:    d->codes.append( Opcode::Pow7 ); break;
                            case Token::Super8:    d->codes.append( Opcode::Pow8 ); break;
                            case Token::Super9:    d->codes.append( Opcode::Pow9 ); break;
                            case Token::Modulo:    d->codes.append( Opcode::Modulo ); break;
                            case Token::Backslash: d->codes.append( Opcode::IntDiv ); break;
                            case Token::LeftShift: d->codes.append( Opcode::LSh ); break;
                            case Token::RightShift: d->codes.append( Opcode::RSh ); break;
                            case Token::Ampersand: d->codes.append( Opcode::BAnd ); break;
                            case Token::Pipe:      d->codes.append( Opcode::BOr ); break;
                            default: break;
                        };
#ifdef EVALUATOR_DEBUG
                        dbg << "    Rule for binary operator" << "\n";
#endif
                    }
                }

                // rule for unary operator:  (op1) (op2) X -> (op1) X
                // conditions: op2 is unary, token is not '('
                // action: push (op2) to result
                // e.g.  "* - 2" becomes "*"
                if ( ! ruleFound && token.asOperator() != Token::LeftPar
                        && syntaxStack.itemCount() >= 3 )
                {
                    Token x = syntaxStack.top();
                    Token op2 = syntaxStack.top( 1 );
                    Token op1 = syntaxStack.top( 2 );
                    if ( ! x.isOperator() && op1.isOperator() && op2.isOperator()
                         && (op2.asOperator() == Token::Plus || op2.asOperator() == Token::Minus) )
                    {
                        ruleFound = true;
                        if ( op2.asOperator() == Token::Minus )
                            d->codes.append( Opcode(Opcode::Neg) );
                    }
#if 0
                    else { // maybe postfix
                        x = op2;
                        op2 = syntaxStack.top();
                        if ( ! x.isOperator() && op1.isOperator() && op2.isOperator()
                             && op2.asOperator() == Token::Exclamation )
                        {
                            ruleFound = true;
                            d->codes.append( Opcode(Opcode::Fact) );
                        }
                    }
#endif
                    if ( ruleFound ) {
                        syntaxStack.pop();
                        syntaxStack.pop();
                        syntaxStack.push( x );
#ifdef EVALUATOR_DEBUG
                        dbg << "    Rule for unary operator" << "\n";
#endif
                    }
                }

                // auxiliary rule for unary operator:  (op) X -> X
                // conditions: op is unary, op is first in syntax stack,
                // token is not '(' or '^' or '!' or any power operator
                // action: push (op) to result
                if ( ! ruleFound && token.asOperator() != Token::LeftPar
                     && token.asOperator() != Token::Exclamation
                     && token.asOperator() != Token::Super0 && token.asOperator() != Token::Super1
                     && token.asOperator() != Token::Super2 && token.asOperator() != Token::Super3
                     && token.asOperator() != Token::Super4 && token.asOperator() != Token::Super5
                     && token.asOperator() != Token::Super6 && token.asOperator() != Token::Super7
                     && token.asOperator() != Token::Super8 && token.asOperator() != Token::Super9
                     && syntaxStack.itemCount() == 2 )
                {
                    Token x = syntaxStack.top();
                    Token op = syntaxStack.top( 1 );
                    if ( ! x.isOperator() && op.isOperator()
                         && (op.asOperator() == Token::Plus || op.asOperator() == Token::Minus) )
                    {
                        ruleFound = true;
                        if ( op.asOperator() == Token::Minus )
                            d->codes.append( Opcode(Opcode::Neg) );
                    } else {
                        x = op;
                        op = syntaxStack.top();
                        if ( ! x.isOperator() && op.isOperator() )
                        {
                            // if we don't really find the rule,
                            // restore ruleFound as if nothing happened
                            // see below
                            bool ruleFoundOldValue = ruleFound;
                            ruleFound = true;
                            if (op.asOperator() == Token::Exclamation)
                                d->codes.append( Opcode(Opcode::Fact) );
                            else if (op.asOperator() == Token::Super0)
                                d->codes.append( Opcode(Opcode::Pow0) );
                            else if (op.asOperator() == Token::Super1)
                                d->codes.append( Opcode(Opcode::Pow1) );
                            else if (op.asOperator() == Token::Super2)
                                d->codes.append( Opcode(Opcode::Pow2) );
                            else if (op.asOperator() == Token::Super3)
                                d->codes.append( Opcode(Opcode::Pow3) );
                            else if (op.asOperator() == Token::Super4)
                                d->codes.append( Opcode(Opcode::Pow4) );
                            else if (op.asOperator() == Token::Super5)
                                d->codes.append( Opcode(Opcode::Pow5) );
                            else if (op.asOperator() == Token::Super6)
                                d->codes.append( Opcode(Opcode::Pow6) );
                            else if (op.asOperator() == Token::Super7)
                                d->codes.append( Opcode(Opcode::Pow7) );
                            else if (op.asOperator() == Token::Super8)
                                d->codes.append( Opcode(Opcode::Pow8) );
                            else if (op.asOperator() == Token::Super9)
                                d->codes.append( Opcode(Opcode::Pow9) );
                            else ruleFound = ruleFoundOldValue;
                        }
                    }
                    if ( ruleFound) {
                        syntaxStack.pop();
                        syntaxStack.pop();
                        syntaxStack.push( x );
#ifdef EVALUATOR_DEBUG
                        dbg << "    Rule for unary operator (auxiliary)" << "\n";
#endif
                    }
                }

                if ( ! ruleFound )
                    break;
            }

            // can't apply rules anymore, push the token
            if ( token.asOperator() != Token::Percent )
                syntaxStack.push( token );
        }
    }

    // syntaxStack must left only one operand and end-of-expression (i.e. InvalidOp)
    d->valid = false;
    if ( syntaxStack.itemCount() == 2 && syntaxStack.top().isOperator()
         && syntaxStack.top().asOperator() == Token::InvalidOp
         && ! syntaxStack.top(1).isOperator() )
    {
        d->valid = true;
    }

#ifdef EVALUATOR_DEBUG
    dbg << "Dump: " << dump() << "\n";
    debugFile.close();
#endif

    // bad parsing ? clean-up everything
    if ( !d->valid ) {
        d->constants.clear();
        d->codes.clear();
        d->identifiers.clear();
    }
}

HNumber Evaluator::evalNoAssign()
{
    QStack<HNumber> stack;
    QStack<QString> refs;
    int index;
    HNumber val1, val2;
    QVector<HNumber> args;
    QString fname;
    Function* function;

    if ( d->dirty ) {
        Tokens tokens = scan( d->expression );

        // invalid expression ?
        if ( ! tokens.valid() ) {
            d->error = tr( "invalid expression" );
            return HNumber( 0 );
        }

        // variable assignment?
        d->assignId = QString();
        if ( tokens.count() > 2 && tokens.at(0).isIdentifier()
             && tokens.at(1).asOperator() == Token::Equal )
        {
            d->assignId = tokens.at( 0 ).text();
            tokens.erase( tokens.begin() );
            tokens.erase( tokens.begin() );
        }

        compile( tokens );
    }

    for ( int pc = 0; pc < d->codes.count(); ++pc ) {
        const Opcode & opcode = d->codes.at( pc );
        index = opcode.index;
        switch ( opcode.type ) {
            // no operation
            case Opcode::Nop:
                break;

                // load a constant, push to stack
            case Opcode::Load:
                val1 = d->constants.at( index );
                stack.push( val1 );
                break;

                // unary operation
            case Opcode::Neg:
                if ( stack.count() < 1 ) {
                    d->error = tr( "invalid expression" );
                    return HMath::nan();
                }
                val1 = stack.pop();
                val1 = d->checkOperatorResult(-val1);
                stack.push( val1 );
                break;

                // binary operation: take two values from stack, do the operation,
                // push the result to stack
            case Opcode::Add:
                if ( stack.count() < 2 ) {
                    d->error = tr( "invalid expression" );
                    return HMath::nan();
                }
                val1 = stack.pop();
                val2 = stack.pop();
                val2 = d->checkOperatorResult(val2 + val1);
                stack.push( val2 );
                break;

            case Opcode::Sub:
                if ( stack.count() < 2 ) {
                    d->error = tr( "invalid expression" );
                    return HMath::nan();
                }
                val1 = stack.pop();
                val2 = stack.pop();
                val2 = d->checkOperatorResult(val2 - val1);
                stack.push( val2 );
                break;

            case Opcode::Mul:
                if ( stack.count() < 2 ) {
                    d->error = tr( "invalid expression" );
                    return HMath::nan();
                }
                val1 = stack.pop();
                val2 = stack.pop();
                val2 = d->checkOperatorResult(val2 * val1);
                stack.push( val2 );
                break;

            case Opcode::Div:
                if ( stack.count() < 2 ) {
                    d->error = tr( "invalid expression" );
                    return HMath::nan();
                }
                val1 = stack.pop();
                val2 = stack.pop();
                val2 = d->checkOperatorResult(val2 / val1);
                stack.push( val2 );
                break;

            case Opcode::Pow:
                if ( stack.count() < 2 ) {
                    d->error = tr( "invalid expression" );
                    return HMath::nan();
                }
                val1 = stack.pop();
                val2 = stack.pop();
                val2 = d->checkOperatorResult(HMath::raise( val2, val1 ));
                stack.push( val2 );
                break;

            case Opcode::Pow0:
                if ( stack.count() < 1 ) {
                    d->error = tr( "invalid expression" );
                    return HMath::nan();
                }
                val1 = stack.pop();
                val1 = d->checkOperatorResult(HMath::raise( val1, 0 ));
                stack.push( val1 );
                break;

            case Opcode::Pow1:
                if ( stack.count() < 1 ) {
                    d->error = tr( "invalid expression" );
                    return HMath::nan();
                }
                val1 = stack.pop();
                val1 = d->checkOperatorResult(HMath::raise( val1, 1 ));
                stack.push( val1 );
                break;

            case Opcode::Pow2:
                if ( stack.count() < 1 ) {
                    d->error = tr( "invalid expression" );
                    return HMath::nan();
                }
                val1 = stack.pop();
                val1 = d->checkOperatorResult(HMath::raise( val1, 2 ));
                stack.push( val1 );
                break;

            case Opcode::Pow3:
                if ( stack.count() < 1 ) {
                    d->error = tr( "invalid expression" );
                    return HMath::nan();
                }
                val1 = stack.pop();
                val1 = d->checkOperatorResult(HMath::raise( val1, 3 ));
                stack.push( val1 );
                break;

            case Opcode::Pow4:
                if ( stack.count() < 1 ) {
                    d->error = tr( "invalid expression" );
                    return HMath::nan();
                }
                val1 = stack.pop();
                val1 = d->checkOperatorResult(HMath::raise( val1, 4 ));
                stack.push( val1 );
                break;

            case Opcode::Pow5:
                if ( stack.count() < 1 ) {
                    d->error = tr( "invalid expression" );
                    return HMath::nan();
                }
                val1 = stack.pop();
                val1 = d->checkOperatorResult(HMath::raise( val1, 5 ));
                stack.push( val1 );
                break;

            case Opcode::Pow6:
                if ( stack.count() < 1 ) {
                    d->error = tr( "invalid expression" );
                    return HMath::nan();
                }
                val1 = stack.pop();
                val1 = d->checkOperatorResult(HMath::raise( val1, 6 ));
                stack.push( val1 );
                break;

            case Opcode::Pow7:
                if ( stack.count() < 1 ) {
                    d->error = tr( "invalid expression" );
                    return HMath::nan();
                }
                val1 = stack.pop();
                val1 = d->checkOperatorResult(HMath::raise( val1, 7 ));
                stack.push( val1 );
                break;

            case Opcode::Pow8:
                if ( stack.count() < 1 ) {
                    d->error = tr( "invalid expression" );
                    return HMath::nan();
                }
                val1 = stack.pop();
                val1 = d->checkOperatorResult(HMath::raise( val1, 8 ));
                stack.push( val1 );
                break;

            case Opcode::Pow9:
                if ( stack.count() < 1 ) {
                    d->error = tr( "invalid expression" );
                    return HMath::nan();
                }
                val1 = stack.pop();
                val1 = d->checkOperatorResult(HMath::raise( val1, 9 ));
                stack.push( val1 );
                break;

            case Opcode::Fact:
                if ( stack.count() < 1 ) {
                    d->error = tr( "invalid expression" );
                    return HMath::nan();
                }
                val1 = stack.pop();
                val1 = d->checkOperatorResult(HMath::factorial( val1 ));
                stack.push( val1 );
                break;

            case Opcode::Modulo:
                if ( stack.count() < 2 ) {
                    d->error = tr( "invalid expression" );
                    return HMath::nan();
                }
                val1 = stack.pop();
                val2 = stack.pop();
                val2 = d->checkOperatorResult(val2 % val1);
                stack.push( val2 );
                break;

            case Opcode::IntDiv:
                if ( stack.count() < 2 ) {
                    d->error = tr( "invalid expression" );
                    return HMath::nan();
                }
                val1 = stack.pop();
                val2 = stack.pop();
                val2 = d->checkOperatorResult(val2 / val1);
                stack.push( HMath::integer(val2) );
                break;

            case Opcode::LSh:
                if ( stack.count() < 2 ) {
                    d->error = tr( "invalid expression" );
                    return HMath::nan();
                }
                val1 = stack.pop();
                val2 = stack.pop();
                val2 = val2 << val1;
                stack.push( val2 );
                break;

            case Opcode::RSh:
                if ( stack.count() < 2 ) {
                    d->error = tr( "invalid expression" );
                    return HMath::nan();
                }
                val1 = stack.pop();
                val2 = stack.pop();
                val2 = val2 >> val1;
                stack.push( val2 );
                break;

            case Opcode::BAnd:
                if ( stack.count() < 2 ) {
                    d->error = tr( "invalid expression" );
                    return HMath::nan();
                }
                val1 = stack.pop();
                val2 = stack.pop();
                val2 &= val1;
                stack.push( val2 );
                break;

            case Opcode::BOr:
                if ( stack.count() < 2 ) {
                    d->error = tr( "invalid expression" );
                    return HMath::nan();
                }
                val1 = stack.pop();
                val2 = stack.pop();
                val2 |= val1;
                stack.push( val2 );
                break;

            // reference
            case Opcode::Ref:
                fname = d->identifiers.at( index );
                if ( has(fname) ) // variable
                    stack.push( get(fname) );
                else { // function
                    function = Functions::instance()->function( fname );
                    if ( function )
                        refs.push( fname );
                    else {
                        d->error = fname + ": " + tr( "unknown function or variable" );
                        return HMath::nan();
                    }
                }
                break;

            // calling function
            case Opcode::Function:
                // must do this first to avoid crash when using vars like functions
                if ( refs.isEmpty() )
                    break;

                fname = refs.pop();
                function = Functions::instance()->function( fname );
                if ( !function ) {
                    d->error = fname + ": " + tr( "unknown function or variable" );
                    return HMath::nan();
                }

                if ( stack.count() < index ) {
                    d->error = tr( "invalid expression" );
                    return HMath::nan();
                }

                args.clear();
                for( ; index; --index )
                    args.insert( args.begin(), stack.pop() );

                stack.push( function->exec(args) );
                if ( ! function->error().isEmpty() ) {
                    d->error = function->error();
                    return HMath::nan();
                }

                break;

            default:
                break;
        }
    }

    // more than one value in stack ? unsuccesfull execution...
    if ( stack.count() != 1 ) {
        d->error = tr( "invalid expression" );
        return HMath::nan();
    }

    HNumber result = stack.pop();

    return result;
}

HNumber Evaluator::eval()
{
    HNumber result = evalNoAssign(); // this sets d->assignId

    // cannot overwrite built-in variables and functions
    if ( d->assignId == QLatin1String("pi")
         || d->assignId == QLatin1String("phi")
         || d->assignId == QLatin1String("e")
         || d->assignId == QLatin1String("ans")
         || Functions::instance()->function(d->assignId) )
    {
        d->error = tr( "%1 is a reserved name, please choose another").arg( d->assignId );
        return HMath::nan();
    }

    // handle variable assignment, e.g. "x=2*4"
    if ( ! d->assignId.isEmpty() )
        set( d->assignId, result );

    return result;
}

HNumber Evaluator::evalUpdateAns()
{
    HNumber result = eval();

    // "ans" is default variable to hold calculation result
    if ( d->error.isEmpty() )
        set( QString("ans"), result );

    return result;
}

void Evaluator::set( const QString & id, HNumber value )
{
    if ( ! id.isEmpty() ) {
        d->variables[id].name  = id;
        d->variables[id].value = value;
    }
}

HNumber Evaluator::get( const QString & id )
{
    if ( id.isEmpty() )
        return HNumber( 0 );

    if ( ! d->variables.contains(id) )
        set( id, HNumber(0) );
    return d->variables.value( id ).value;
}

bool Evaluator::has( const QString & id )
{
    return id.isEmpty() ? false : d->variables.contains( id );
}

void Evaluator::remove( const QString & id )
{
    d->variables.remove( id );
}

QVector<Variable> Evaluator::variables() const
{
    QVector<Variable> result;

    for ( QMap<QString,Variable>::Iterator it = d->variables.begin(); it != d->variables.end();
          ++it )
    {
        Variable var;
        const char * ASCII;
        var.name = it.value().name;
        ASCII = var.name.toLatin1();
        var.value = it.value().value;
        result.append( var );
    }

    return result;
}

void Evaluator::clearVariables()
{
  HNumber ansBackup = get( QString("ans") );

  d->variables.clear();

  set( QString("ans"), ansBackup );
  set( QString("pi"), HMath::pi() );
  set( QString("phi"), HMath::phi() );
  set( QString("e"), HMath::e() );
}

QString Evaluator::autoFix( const QString & expr )
{
#ifdef _BISON
    //SglExprLex::self().autoFix(expr);
#endif

    int par = 0;
    QString result;

    // strip off all funny characters
    for( int c = 0; c < expr.length(); ++c )
        if ( expr.at(c) >= QChar(32) )
            result.append( expr.at(c) );

    // no extra whitespaces at the beginning and at the end
    result = result.trimmed();

    // strip trailing equal sign (=)
    while( result.endsWith("=") )
        result = result.left( result.length() - 1 );

    // automagically close all parenthesis
    Tokens tokens = Evaluator::scan( result );
    if ( tokens.count() ) {
        for( int i = 0; i < tokens.count(); ++i )
            if ( tokens.at(i).asOperator() == Token::LeftPar )
                par++;
            else if ( tokens.at(i).asOperator() == Token::RightPar )
                par--;

        if ( par < 0 )
            par = 0;

        // if the scanner stops in the middle, do not bother to apply fix
        const Token & lastToken = tokens.at( tokens.count() - 1 );
        if ( lastToken.pos() + lastToken.text().length() >= result.length() )
            while ( par-- )
                result.append( ')' );
    }

    // special treatment for simple function
    // e.g. "cos" is regarded as "cos(ans)"
    if ( ! result.isEmpty() ) {
        Tokens tokens = Evaluator::scan( result );

        if ( tokens.count() == 1 && tokens.at(0).isIdentifier()
             && Functions::instance()->function(tokens.at(0).text()) )
        {
            result.append( "(ans)" );
        }
    }

    return result;
}

QString Evaluator::dump() const
{
    QString result;
    int c;

    if ( d->dirty ) {
        Tokens tokens = scan( d->expression );
        compile( tokens );
    }

    result = QString( "Expression: [%1]\n" ).arg( d->expression );

    result.append( "  Constants:\n" );
    for ( c = 0; c < d->constants.count(); ++c ) {
        QString vtext;
        HNumber val = d->constants.at( c );
        char* ss = HMath::format( val, 'f' );
        result += QString( "    #%1 = %2\n").arg( c ).arg( ss );
        free( ss );
    }

    result.append( "\n" );
    result.append( "  Identifiers:\n" );
    for( c = 0; c < d->identifiers.count(); ++c ) {
        QString vtext;
        result += QString( "    #%1 = %2\n" ).arg( c ).arg( d->identifiers.at(c) );
    }

    result.append( "\n" );
    result.append( "  Code:\n" );
    for( int i = 0; i < d->codes.count(); ++i ) {
        QString ctext;
        switch ( d->codes.at(i).type ) {
            case Opcode::Load: ctext = QString( "Load #%1" ).arg( d->codes.at(i).index ); break;
            case Opcode::Ref: ctext = QString( "Ref #%1" ).arg( d->codes.at(i).index ); break;
            case Opcode::Function: ctext = QString( "Function (%1)" ).arg( d->codes.at(i).index );
                                   break;
            case Opcode::Add: ctext = "Add"; break;
            case Opcode::Sub: ctext = "Sub"; break;
            case Opcode::Mul: ctext = "Mul"; break;
            case Opcode::Div: ctext = "Div"; break;
            case Opcode::Neg: ctext = "Neg"; break;
            case Opcode::Pow: ctext = "Pow"; break;
            case Opcode::Pow0: ctext = "Pow0"; break;
            case Opcode::Pow1: ctext = "Pow1"; break;
            case Opcode::Pow2: ctext = "Pow2"; break;
            case Opcode::Pow3: ctext = "Pow3"; break;
            case Opcode::Pow4: ctext = "Pow4"; break;
            case Opcode::Pow5: ctext = "Pow5"; break;
            case Opcode::Pow6: ctext = "Pow6"; break;
            case Opcode::Pow7: ctext = "Pow7"; break;
            case Opcode::Pow8: ctext = "Pow8"; break;
            case Opcode::Pow9: ctext = "Pow9"; break;
            case Opcode::Fact: ctext = "Fact"; break;
            case Opcode::LSh: ctext = "LSh"; break;
            case Opcode::RSh: ctext = "RSh"; break;
            case Opcode::BAnd: ctext = "BAnd"; break;
            case Opcode::BOr: ctext = "BOr"; break;
            default: ctext = "Unknown"; break;
        }
        result.append( "   " ).append( ctext ).append("\n");
    }

    return result;
}

