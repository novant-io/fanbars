//
// Copyright (c) 2020, Andy Frank
// Licensed under the MIT License
//
// History:
//   30 July 2020  Andy Frank  Creation
//

*************************************************************************
** TokenType
*************************************************************************

internal enum class TokenType
{
  openBar,
  closeBar,
  comment,
  keyword,
  identifier,
  raw,
  eos
}

*************************************************************************
** Token
*************************************************************************

internal const class Token
{
  ** Ctor.
  new make(TokenType t, Str v) { this.type=t; this.val=v }

  ** Token type.
  const TokenType type

  ** Token literval val.
  const Str val

  Bool isOpenBar()    { type == TokenType.openBar    }
  Bool isCloseBar()   { type == TokenType.closeBar   }
  Bool isComment()    { type == TokenType.comment    }
  Bool isKeyword()    { type == TokenType.keyword    }
  Bool isIdentifier() { type == TokenType.identifier }
  Bool isRaw()        { type == TokenType.raw        }
  Bool isEos()        { type == TokenType.eos        }

  override Str toStr() { "${type}='${val}'" }
}

*************************************************************************
** Parser
*************************************************************************

internal class Parser
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Ctor.
  new make(InStream in)
  {
    // TODO
    this.podName  = "<pod>"
    this.filename = "<file>"

    this.in = in
  }

  ** Parse input stream into AST tree.
  Def parse()
  {
    root := Def {}
    stack.add(root)
    Token? token

    while ((token = nextToken).isEos == false)
    {
      parent := stack.last
      switch (token.type)
      {
        case TokenType.raw:
          def := RawTextDef { it.text=token.val }
          parent.children.add(def)

        case TokenType.openBar:
          token = nextToken
          switch (token.type)
          {
            case TokenType.identifier:
              def := VarDef { it.name=token.val }
              parent.children.add(def)

            case TokenType.keyword:
              switch (token.val)
              {
                case "#if":
                  token = nextToken(TokenType.identifier)
                  var := VarDef { it.name=token.val }
                  def := IfDef { it.var=var }
                  parent.children.push(def)
                  stack.push(def)

                case "#each":
                  token = nextToken(TokenType.identifier)
                  iter := VarDef { it.name=token.val }
                  token = nextToken(TokenType.identifier)
                  if (token.val != "in") throw unexpectedToken(token)
                  token = nextToken(TokenType.identifier)
                  var := VarDef { it.name=token.val }
                  def := EachDef { it.iter=iter; it.var=var }
                  parent.children.push(def)
                  stack.push(def)

                case "/if":   stack.pop
                case "/each": stack.pop

                default: throw unexpectedToken(token)
              }

            default: throw unexpectedToken(token)
          }
          // eat closing }}
          nextToken(TokenType.closeBar)

        default: throw unexpectedToken(token)
      }
    }

    if (stack.size > 1)
    {
      if (stack.last is IfDef) throw parseErr("Missing closing {{/if}}")
      else throw parseErr("Missing closing {{/each}}")
    }

    return root
  }

//////////////////////////////////////////////////////////////////////////
// Tokenizer
//////////////////////////////////////////////////////////////////////////

  ** Read next token from stream.  If 'type' is non-null
  ** and does match read token, throw ParseErr.
  private Token nextToken(TokenType? type := null)
  {
    // read next non-comment token
    token := readNextToken
    while (token?.isComment == true) token = readNextToken

    // wrap in eos if hit end of file
    if (token == null) token = Token(TokenType.eos, "")

    // check match
    if (type != null && token?.type != type) throw unexpectedToken(token)

    return token
  }

  ** Read next token from stream or 'null' if EOS.
  private Token? readNextToken()
  {
    buf.clear

    // read next char
    ch := read
    if (ch == null) return null

    // open {{
    if (ch == '{' && peek == '{')
    {
      read // eat second }
      tokInBar = true
      return Token(TokenType.openBar, "{{")
    }

    // close }}
    if (ch == '}' && peek == '}')
    {
      read // eat second }
      tokInBar = false
      return Token(TokenType.closeBar, "}}")
    }

    // check if inside a bar statement
    if (tokInBar)
    {
      t := TokenType.identifier

      if (ch == '#' || ch == '/')
      {
        t = TokenType.keyword
        buf.addChar(ch)
        ch = read
      }

      while (ch.isAlphaNum)
      {
        buf.addChar(ch)
        ch = read
      }

      // pushback closing bar if we read into it
      if (ch == '}') in.unreadChar(ch)

      return Token(t, buf.toStr)
    }

    // raw text
    while (ch != null)
    {
      if (ch == '{' && peek == '{')
      {
        // pushback closing bar if we read into it
        in.unreadChar(ch)
        break
      }

      buf.addChar(ch)
      ch = read
    }

    return Token(TokenType.raw, buf.toStr)
  }

  ** Read next char in stream.
  private Int? read()
  {
    ch := in.readChar
    if (ch == '\n') line++
    return ch
  }

  ** Peek next char in stream.
  private Int? peek() { in.peekChar }

  ** Throw ParseErr
  private Err parseErr(Str msg)
  {
    ParseErr("${msg} [${filename}:${line}]")
  }

  ** Throw ParseErr
  private Err unexpectedToken(Token token)
  {
    token.isEos
      ? ParseErr("Unexpected end of stream [${filename}:${line}]")
      : ParseErr("Unexpected token: '$token.val' [${filename}:${line}]")
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private const Str podName        // podName
  private const Str filename       // name of file to parse
  private InStream in              // input
  private Int line := 1            // current line
  private Def[] stack := [,]       // AST node stack
  private Bool tokInBar := false   // are we tokenizing inside {{ ... }}
  private StrBuf buf := StrBuf()   // resuse buf in nextToken
}