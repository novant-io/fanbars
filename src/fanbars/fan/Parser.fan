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
  openTriBar,
  closeTriBar,
  comment,
  keyword,
  identifier,
  dot,
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

  Bool isOpenBar()     { type == TokenType.openBar     }
  Bool isCloseBar()    { type == TokenType.closeBar    }
  Bool isOpenTriBar()  { type == TokenType.openTriBar  }
  Bool isCloseTriBar() { type == TokenType.closeTriBar }
  Bool isComment()     { type == TokenType.comment     }
  Bool isKeyword()     { type == TokenType.keyword     }
  Bool isIdentifier()  { type == TokenType.identifier  }
  Bool isDot()         { type == TokenType.dot         }
  Bool isRaw()         { type == TokenType.raw         }
  Bool isEos()         { type == TokenType.eos         }

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

        case TokenType.openTriBar:
          def := parseVarDef(null, Int.maxVal, false)
          parent.children.add(def)
          nextToken(TokenType.closeTriBar) // eat closing }}}

        case TokenType.openBar:
          token = nextToken
          switch (token.type)
          {
            case TokenType.identifier:
              def := parseVarDef(token)
              parent.children.add(def)

            case TokenType.keyword:
              switch (token.val)
              {
                case "#if":
                  var := parseVarDef
                  def := IfDef { it.var=var }
                  parent.children.push(def)
                  stack.push(def)

                case "#each":
                  iter := parseVarDef(null, 1)
                  token = nextToken(TokenType.identifier)
                  if (token.val != "in") throw unexpectedToken(token)
                  var := parseVarDef
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

  ** Parse a variable path.
  private VarDef parseVarDef(Token? token := null, Int maxPath := Int.maxVal, Bool escape := true)
  {
    if (token == null) token = nextToken(TokenType.identifier)
    path := [token.val]
    while (peek == '.' && path.size < maxPath)
    {
      nextToken(TokenType.dot)
      token = nextToken(TokenType.identifier)
      path.add(token.val)
    }
    return VarDef { it.escape=escape; it.path=path }
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
      if (peek == '{')
      {
        read // eat third }
        return Token(TokenType.openTriBar, "{{{")
      }
      return Token(TokenType.openBar, "{{")
    }

    // close }}
    if (ch == '}' && peek == '}')
    {
      read // eat second }
      tokInBar = false
      if (peek == '}')
      {
        read // eat third }
        return Token(TokenType.closeTriBar, "}}}")
      }
      return Token(TokenType.closeBar, "}}")
    }

    // check if inside a bar statement
    if (tokInBar)
    {
      // eat leading space
      while (ch.isSpace) ch = read

      // check for dot sep
      if (ch == '.') return Token(TokenType.dot, ".")

      // keyword
      if (ch == '#' || ch == '/')
      {
        buf.addChar(ch)
        if (peek?.isAlpha != true) throw unexpectedChar(peek)
        while (peek?.isAlpha == true) buf.addChar(read)
        return Token(TokenType.keyword, buf.toStr)
      }

      // identifier
      if (!ch.isAlpha) throw unexpectedChar(ch)
      buf.addChar(ch)
      while (isValidIdentiferChar(peek)) buf.addChar(read)
      return Token(TokenType.identifier, buf.toStr)
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

  ** Return 'true' if ch is a valid identifier char
  private Bool isValidIdentiferChar(Int ch)
  {
    if (ch.isAlphaNum) return true
    if (ch == '-') return true
    if (ch == '_') return true
    return false
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
  private Err unexpectedChar(Int? ch)
  {
    ch == null
      ? parseErr("Unexpected end of stream")
      : parseErr("Unexpected char: '$ch.toChar'")
  }

  ** Throw ParseErr
  private Err unexpectedToken(Token token)
  {
    token.isEos
      ? parseErr("Unexpected end of stream")
      : parseErr("Unexpected token: '$token.val'")
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