//
// Copyright (c) 2020, Novant LLC
// Licensed under the MIT License
//
// History:
//   30 July 2020  Andy Frank  Creation
//

*************************************************************************
** TokenType
*************************************************************************

@Js internal enum class TokenType
{
  openStash,
  closeStash,
  openTriStash,
  closeTriStash,
  comment,
  keyword,
  identifier,
  literal,
  dot,
  raw,
  eos
}

*************************************************************************
** Token
*************************************************************************

@Js internal const class Token
{
  ** Ctor.
  new make(TokenType t, Str v) { this.type=t; this.val=v }

  ** Token type.
  const TokenType type

  ** Token literval val.
  const Str val

  Bool isOpenStash()     { type == TokenType.openStash     }
  Bool isCloseStash()    { type == TokenType.closeStash    }
  Bool isOpenTriStash()  { type == TokenType.openTriStash  }
  Bool isCloseTriStash() { type == TokenType.closeTriStash }
  Bool isComment()       { type == TokenType.comment       }
  Bool isKeyword()       { type == TokenType.keyword       }
  Bool isIdentifier()    { type == TokenType.identifier    }
  Bool isLiteral()       { type == TokenType.literal       }
  Bool isDot()           { type == TokenType.dot           }
  Bool isRaw()           { type == TokenType.raw           }
  Bool isEos()           { type == TokenType.eos           }

  override Str toStr() { "${type}='${val}'" }
}

*************************************************************************
** Parser
*************************************************************************

@Js internal class Parser
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

    while (true)
    {
      // read next token or break if eos
      token = nextToken
      if (token.isEos) break

      parent := stack.last
      switch (token.type)
      {
        case TokenType.raw:
          def := RawTextDef { it.text=token.val }
          parent.children.add(def)

        case TokenType.openTriStash:
          def := parseVarDef(null, Int.maxVal, false)
          parent.children.add(def)
          nextToken(TokenType.closeTriStash) // eat closing }}}

        case TokenType.openStash:
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
                  tmp := nextToken
                  Str? op
                  LiteralDef? rhs
                  if (tmp.val != "is" && tmp.val != "isnot") unreadToken(tmp)
                  else
                  {
                    op  = tmp.val
                    tmp = nextToken(TokenType.literal)
                    rhs = LiteralDef { it.val=tmp.val }
                  }
                  def := IfDef { it.var=var; it.op=op; it.rhs=rhs }
                  parent.children.push(def)
                  stack.push(def)

                case "#ifnot":
                  var := parseVarDef
                  def := IfNotDef { it.var=var }
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

                case "#gen":
                  func := parseVarDef
                  def  := GenDef { it.func=func }
                  parent.children.push(def)

                case "#partial":
                  var := parseVarDef(null, 1)
                  def := PartialDef { it.var=var }
                  parent.children.push(def)

                case "/if":
                  last := stack.pop
                  if (last isnot IfDef) throw unmatchedDef(last)

                case "/ifnot":
                  last := stack.pop
                  if (last isnot IfNotDef) throw unmatchedDef(last)

                case "/each":
                  last := stack.pop
                  if (last isnot EachDef) throw unmatchedDef(last)

                default: throw unexpectedToken(token)
              }

            default: throw unexpectedToken(token)
          }
          // eat closing }}
          nextToken(TokenType.closeStash)

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

  ** Unread given token.
  private Void unreadToken(Token token)
  {
    pushback.push(token)
  }

  ** Read next token from stream or 'null' if EOS.
  private Token? readNextToken()
  {
    // first check pushback
    if (pushback.size > 0) return pushback.pop

    buf.clear

    // read next char
    ch := read
    if (ch == null) return null

    // open {{
    if (ch == '{' && peek == '{')
    {
      read // eat second {

      // comment
      if (peek == '!')
      {
        read // eat !
        cnum := 1 // number of nested comments
        ch = read; if (ch != '-') throw unexpectedChar(ch)
        ch = read; if (ch != '-') throw unexpectedChar(ch)
        while (true)
        {
          ch = read
          if (ch == null) throw unexpectedChar(null)
          if (ch == '-' && peek == '-')
          {
            // check for nested comments
            if (buf.size > 2 && buf[-3..-1] == "{{!")
            {
              cnum++
              buf.addChar(ch)
              buf.addChar(read)  // eat second '-'
              continue
            }

            // check for closing comment
            stack := [ch, read]
            if (peek == '}')
            {
              stack.add(read)
              if (peek == '}')
              {
                read
                cnum--
                if (cnum == 0) break
                else continue
              }
            }

            // check for EOS here before we unread to avoid inf loop
            if (peek == null) throw unexpectedChar(null)
            stack.eachr |x| { in.unread(x) }
          }
          buf.addChar(ch)
        }
        return Token(TokenType.comment, buf.toStr.trim)
      }

      // stash directive
      tokInStash = true
      if (peek == '{')
      {
        read // eat third }
        return Token(TokenType.openTriStash, "{{{")
      }

      return Token(TokenType.openStash, "{{")
    }

    // close }}
    if (ch == '}' && peek == '}')
    {
      read // eat second }
      tokInStash = false
      if (peek == '}')
      {
        read // eat third }
        return Token(TokenType.closeTriStash, "}}}")
      }
      return Token(TokenType.closeStash, "}}")
    }

    // check if inside a stash statement
    if (tokInStash)
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
        if (ch == '/') while (peek.isSpace) ch = read // eat trailing space only for {{/xxx}}
        return Token(TokenType.keyword, buf.toStr)
      }

      // literal
      if (ch == '\'' || ch == '\"')
      {
        delim := ch
        while (peek != delim)
        {
          if (peek == null) throw unexpectedChar(null)
          buf.addChar(read)
        }
        read  // eat trailing delim
        while (peek.isSpace) ch = read // eat trailing space (TODO is this right?)
        return Token(TokenType.literal, buf.toStr)
      }

      // identifier
      if (!ch.isAlpha && ch != '_') throw unexpectedChar(ch)
      buf.addChar(ch)
      while (isValidIdentiferChar(peek)) buf.addChar(read)
      while (peek.isSpace) ch = read // eat trailing space
      if (buf[0] == '_' && buf.size == 1) throw parseErr("Illegal identifier '${buf}'")
      return Token(TokenType.identifier, buf.toStr)
    }

    // raw text
    while (ch != null)
    {
      if (ch == '{' && peek == '{')
      {
        // pushback closing stash if we read into it
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

  ** Throw ParseErr
  private Err unmatchedDef(Def? def)
  {
    if (def is IfDef)    return parseErr("Expecting {{/if}}")
    if (def is IfNotDef) return parseErr("Expecting {{/ifnot}}")
    if (def is EachDef)  return parseErr("Expecting {{/each}}")
    return parseErr("Unmatched closing statement")
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private const Str podName         // podName
  private const Str filename        // name of file to parse
  private InStream in               // input
  private Int line := 1             // current line
  private Def[] stack := [,]        // AST node stack
  private Int commentDepth := 0     // track comment {{!-- depth
  private Bool tokInStash := false  // are we tokenizing inside {{ ... }}
  private StrBuf buf := StrBuf()    // resuse buf in nextToken
  private Token[] pushback := [,]   // for unreadToken
}