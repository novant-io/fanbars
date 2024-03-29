//
// Copyright (c) 2020, Novant LLC
// Licensed under the MIT License
//
// History:
//   30 July 2020  Andy Frank  Creation
//

@Js class ParserTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Empty
//////////////////////////////////////////////////////////////////////////

  Void testEmpty()
  {
    // empty content is ok
    d := p("")
    verifyEq(d.children.size, 0)

    // a single empty bars is not
    verifyErr(ParseErr#) { p("{{}}") }
  }

//////////////////////////////////////////////////////////////////////////
// Raw
//////////////////////////////////////////////////////////////////////////

  Void testRaw()
  {
    s := "just some raw text"
    d := p(s)
    verifyEq(d.children.size, 1)
    verifyRaw(d.children.first, s)

    s = "  make sure  spaces are    preserved   "
    d = p(s)
    verifyEq(d.children.size, 1)
    verifyRaw(d.children.first, s)

    s = "  make sure  spaces are
         and newlines are    preserved
           as well"
    d = p(s)
    verifyEq(d.children.size, 1)
    verifyRaw(d.children.first, s)
  }

//////////////////////////////////////////////////////////////////////////
// Vars
//////////////////////////////////////////////////////////////////////////

  Void testVars()
  {
    d := p("{{foo}}")
    verifyEq(d.children.size, 1)
    verifyVar(d.children.first, ["foo"])

    d = p("{{foo123}}")
    verifyEq(d.children.size, 1)
    verifyVar(d.children.first, ["foo123"])

    d = p("{{foo-bar}}")
    verifyEq(d.children.size, 1)
    verifyVar(d.children.first, ["foo-bar"])

    d = p("{{foo_bar}}")
    verifyEq(d.children.size, 1)
    verifyVar(d.children.first, ["foo_bar"])

    d = p("{{ foo}}")
    verifyEq(d.children.size, 1)
    verifyVar(d.children.first, ["foo"])

    d = p("{{ foo }}")
    verifyEq(d.children.size, 1)
    verifyVar(d.children.first, ["foo"])

    d = p("{{_foo}}")
    verifyEq(d.children.size, 1)
    verifyVar(d.children.first, ["_foo"])

    d = p("{{_foo_bar}}")
    verifyEq(d.children.size, 1)
    verifyVar(d.children.first, ["_foo_bar"])

    verifyErr(ParseErr#) { p("{{123}}") }
    verifyErr(ParseErr#) { p("{{_}}") }
    verifyErr(ParseErr#) { p("{{-}}") }
    verifyErr(ParseErr#) { p("{{-foo}}") }
  }

  Void testVarsMulti()
  {
    d := p("{{foo}}{{bar}}")
    verifyEq(d.children.size, 2)
    verifyVar(d.children[0], ["foo"])
    verifyVar(d.children[1], ["bar"])

    d = p("ok {{foo}}")
    verifyEq(d.children.size, 2)
    verifyRaw(d.children[0], "ok ")
    verifyVar(d.children[1], ["foo"])

    d = p("ok {{foo}}, and {{bar}} how?")
    verifyEq(d.children.size, 5)
    verifyRaw(d.children[0], "ok ")
    verifyVar(d.children[1], ["foo"])
    verifyRaw(d.children[2], ", and ")
    verifyVar(d.children[3], ["bar"])
    verifyRaw(d.children[4], " how?")

    d = p(" {{foo}} {{bar}} ")
    verifyEq(d.children.size, 5)
    verifyRaw(d.children[0], " ")
    verifyVar(d.children[1], ["foo"])
    verifyRaw(d.children[2], " ")
    verifyVar(d.children[3], ["bar"])
    verifyRaw(d.children[4], " ")
  }

  Void testVarsPath()
  {
    d := p("{{a.b}}")
    verifyEq(d.children.size, 1)
    verifyVar(d.children.first, ["a","b"])

    d = p("{{a.b.foo-bar.x5.zoo}}")
    verifyEq(d.children.size, 1)
    verifyVar(d.children.first, ["a","b","foo-bar","x5","zoo"])

    verifyErr(ParseErr#) { p("{{.}}") }
    verifyErr(ParseErr#) { p("{{.foo}}") }
    verifyErr(ParseErr#) { p("{{foo..bar}}") }
  }

  Void testVarsEscape()
  {
    d := p("{{{foo}}}")
    verifyEq(d.children.size, 1)
    verifyVar(d.children.first, ["foo"], false)

    d = p("{{{ foo}}}")
    verifyEq(d.children.size, 1)
    verifyVar(d.children.first, ["foo"], false)

    d = p("{{{ foo }}}")
    verifyEq(d.children.size, 1)
    verifyVar(d.children.first, ["foo"], false)

    d = p("{{{a.b.c}}}")
    verifyEq(d.children.size, 1)
    verifyVar(d.children.first, ["a","b","c"], false)
  }

//////////////////////////////////////////////////////////////////////////
// If
//////////////////////////////////////////////////////////////////////////

  Void testIfBasic()
  {
    d := p("{{#if foo}}hello{{/if}}")
    verifyEq(d.children.size, 1)
    verifyIf(d.children[0], ["foo"])
    verifyRaw(d.children[0].children[0], "hello")

    d = p("{{ #if foo }}hello{{ /if }}")
    verifyEq(d.children.size, 1)
    verifyIf(d.children[0], ["foo"])
    verifyRaw(d.children[0].children[0], "hello")

    verifyErr(ParseErr#) { p("{{#if}}") }
    verifyErr(ParseErr#) { p("{{#if name}}") }
    verifyErr(ParseErr#) { p("{{#if name}} hello") }
  }

  Void testIfNotBasic()
  {
    d := p("{{#ifnot foo}}hello{{/ifnot}}")
    verifyEq(d.children.size, 1)
    verifyIfNot(d.children[0], ["foo"])
    verifyRaw(d.children[0].children[0], "hello")

    d = p("{{ #ifnot foo }}hello{{ /ifnot }}")
    verifyEq(d.children.size, 1)
    verifyIfNot(d.children[0], ["foo"])
    verifyRaw(d.children[0].children[0], "hello")

    verifyErr(ParseErr#) { p("{{#ifnot}}") }
    verifyErr(ParseErr#) { p("{{#ifnot name}}") }
    verifyErr(ParseErr#) { p("{{#ifnot name}} hello") }
  }

  Void testIfNested()
  {
    // srip spaces/newlines to make test cases easier
    d := p("{{#if foo}}
              hello
              {{#if bar}}
                world
              {{/if}}
            {{/if}}".splitLines.join("") |s| { s.trim })

    // root
    verifyEq(d.children.size, 1)
    verifyIf(d.children.first, ["foo"])

    // outer #if
    d = d.children.first
    verifyEq(d.children.size, 2)
    verifyRaw(d.children[0], "hello")
    verifyIf(d.children[1], ["bar"])

    // inner #if
    d = d.children[1]
    verifyEq(d.children.size, 1)
    verifyRaw(d.children[0], "world")

    // unmatched closing staches
    verifyErr(ParseErr#) {
      p("{{#if foo}}
           hello
           {{#ifnot bar}}world{{/if}}
           {{/ifnot}}")
    }
  }

  Void testIfIs()
  {
    // single quote
    d := p("{{#if foo is 'xyz'}}hello{{/if}}")
    verifyEq(d.children.size, 1)
    verifyIf(d.children[0], ["foo"], "is", "xyz")
    verifyRaw(d.children[0].children[0], "hello")

    // double quote
    d = p("{{#if foo is \"xyz\"}}hello{{/if}}")
    verifyEq(d.children.size, 1)
    verifyIf(d.children[0], ["foo"], "is", "xyz")
    verifyRaw(d.children[0].children[0], "hello")

    // whitespace
    d = p("{{ #if foo  is  'a b c '  }}hello{{ /if }}")
    verifyEq(d.children.size, 1)
    verifyIf(d.children[0], ["foo"], "is", "a b c ")
    verifyRaw(d.children[0].children[0], "hello")

    // isnot
    d = p("{{#if foo isnot 'xyz'}}hello{{/if}}")
    verifyEq(d.children.size, 1)
    verifyIf(d.children[0], ["foo"], "isnot", "xyz")
    verifyRaw(d.children[0].children[0], "hello")

    // verifyErr(ParseErr#) { p("{{#if name is}} hello {{/if}}") }
    // verifyErr(ParseErr#) { p("{{#if name is xyz}} hello {{/if}}") }
    // verifyErr(ParseErr#) { p("{{#if name is 'xyz}} hello {{/if}}") }
    // verifyErr(ParseErr#) { p("{{#if name is \"xyz'}} hello {{/if}}") }
  }

//////////////////////////////////////////////////////////////////////////
// Evlis
//////////////////////////////////////////////////////////////////////////

  Void testElivs()
  {
    // single quote
    d := p("{{foo ?: 'xyz'}}")
    verifyEq(d.children.size, 2)
    verifyIf(d.children[0], ["foo"])
    verifyVar(d.children[0].children[0], ["foo"])
    verifyIfNot(d.children[1], ["foo"])
    verifyRaw(d.children[1].children[0], "xyz")

    // // double quote
    d = p("{{foo ?: \"xyz\"}}")
    verifyEq(d.children.size, 2)
    verifyIf(d.children[0], ["foo"])
    verifyVar(d.children[0].children[0], ["foo"])
    verifyIfNot(d.children[1], ["foo"])
    verifyRaw(d.children[1].children[0], "xyz")

    // whitespace
    d = p("{{ foo   ?:  \"xyz\"    }}")
    verifyEq(d.children.size, 2)
    verifyIf(d.children[0], ["foo"])
    verifyVar(d.children[0].children[0], ["foo"])
    verifyIfNot(d.children[1], ["foo"])
    verifyRaw(d.children[1].children[0], "xyz")

    verifyErr(ParseErr#) { p("{{foo ?: }}") }
    verifyErr(ParseErr#) { p("{{foo ? 'bar'}}") }
  }

//////////////////////////////////////////////////////////////////////////
// Each
//////////////////////////////////////////////////////////////////////////

  Void testEachBasic()
  {
    d := p("{{#each v in items}}test{{/each}}")
    verifyEq(d.children.size, 1)
    verifyEach(d.children[0], "v", ["items"])
    verifyRaw(d.children[0].children[0], "test")

    d = p("{{ #each v in items }}test{{ /each }}")
    verifyEq(d.children.size, 1)
    verifyEach(d.children[0], "v", ["items"])
    verifyRaw(d.children[0].children[0], "test")

    verifyErr(ParseErr#) { p("{{#each}}") }
    verifyErr(ParseErr#) { p("{{#each v in}}") }
    verifyErr(ParseErr#) { p("{{#each v in foo}}") }
    verifyErr(ParseErr#) { p("{{#each v in foo}} hello") }
  }

//////////////////////////////////////////////////////////////////////////
// Comments
//////////////////////////////////////////////////////////////////////////

  Void testComments()
  {
    d := p("{{!-- hello --}}")
    verifyEq(d.children.size, 0)

    d = p("{{!-- hello {{var}} {{#if x}}bar{{/if}} --}}")
    verifyEq(d.children.size, 0)

    d = p("{{!-- foo --}}{{!-- bar --}}")
    verifyEq(d.children.size, 0)

    verifyErr(ParseErr#) { p("{{! foo --}}")  }
    verifyErr(ParseErr#) { p("{{!- foo --}}") }
    verifyErr(ParseErr#) { p("{{!-- foo")     }
    verifyErr(ParseErr#) { p("{{!-- foo -")   }
    verifyErr(ParseErr#) { p("{{!-- foo --")  }
    verifyErr(ParseErr#) { p("{{!-- foo --}") }
    verifyErr(ParseErr#) { p("{{!-- foo }}{{!-- bar}}") }
  }

  Void testCommentsNested()
  {
    d := p("{{!-- foo {{!-- bar --}} zar --}}")
    verifyEq(d.children.size, 0)

    d = p("{{!--
            foo
             {{!--
              bar
               {{!--
                zar
               --}}
             --}}
           --}}")
    verifyEq(d.children.size, 0)

    verifyErr(ParseErr#) { p("{{!-- foo {{!-- bar --}}") }
  }

//////////////////////////////////////////////////////////////////////////
// Gen
//////////////////////////////////////////////////////////////////////////

  Void testGen()
  {
    d := p("{{#gen func}}")
    verifyEq(d.children.size, 1)
    verifyGen(d.children[0], "func")
  }

//////////////////////////////////////////////////////////////////////////
// Partials
//////////////////////////////////////////////////////////////////////////

  Void testPartials()
  {
    d := p("{{#partial header}}")
    verifyEq(d.children.size, 1)
    verifyPartial(d.children[0], "header")
  }

//////////////////////////////////////////////////////////////////////////
// Helpers
//////////////////////////////////////////////////////////////////////////

  Void testHelpers()
  {
    d := p("{{#helper acme::Bar.something foo}}")
    verifyEq(d.children.size, 1)
    verifyHelper(d.children[0], "acme::Bar.something", ["foo"])

    d = p("{{#helper acme::Bar.something foo bar car}}")
    verifyEq(d.children.size, 1)
    verifyHelper(d.children[0], "acme::Bar.something", ["foo", "bar", "car"])

    // literal
    d = p("{{#helper acme::Bar.something \"foo\"}}")
    verifyEq(d.children.size, 1)
    verifyHelper(d.children[0], "acme::Bar.something", ["foo"])

    // literals
    d = p("{{#helper acme::Bar.something \"foo\" \"123\"}}")
    verifyEq(d.children.size, 1)
    verifyHelper(d.children[0], "acme::Bar.something", ["foo", "123"])

    // mixed
    d = p("{{#helper acme::Bar.something foo \"bar\"}}")
    verifyEq(d.children.size, 1)
    verifyHelper(d.children[0], "acme::Bar.something", ["foo", "bar"])
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  private Def p(Str text)
  {
    buf := Buf().print(text).flip
    def := Parser(buf.in).parse
//    def.dump(Env.cur.out, 0)
    return def
  }

  private Void verifyRaw(Def d, Str text)
  {
    verifyEq(d.typeof, RawTextDef#)
    verifyEq(d->text,  text)
  }

  private Void verifyLiteral(Def d, Str val)
  {
    verifyEq(d.typeof, LiteralDef#)
    verifyEq(d->val, val)
  }

  private Void verifyVar(Def d, Str[] path, Bool escape := true)
  {
    verifyEq(d.typeof, VarDef#)
    verifyEq(d->escape, escape)
    Str[] p := d->path
    verifyEq(p.size, path.size)
    p.size.times |i| { verifyEq(p[i], path[i]) }
  }

  private Void verifyIf(Def d, Str[] path, Str? op := null, Str? rhs := null)
  {
    verifyEq(d.typeof, IfDef#)
    verifyVar(d->var, path)
    if (rhs == null) verifyNull(d->rhs)
    else
    {
      verifyEq(d->op, op)
      verifyLiteral(d->rhs, rhs)
    }
  }

  private Void verifyIfNot(Def d, Str[] path)
  {
    verifyEq(d.typeof, IfNotDef#)
    verifyVar(d->var, path)
  }

  private Void verifyEach(Def d, Str iter, Str[] path)
  {
    verifyEq(d.typeof, EachDef#)
    verifyVar(d->iter, [iter])
    verifyVar(d->var, path)
  }

  private Void verifyGen(Def d, Str ref)
  {
    verifyEq(d.typeof, GenDef#)
    verifyVar(d->func, [ref])
  }

  private Void verifyPartial(Def d, Str ref)
  {
    verifyEq(d.typeof, PartialDef#)
    verifyVar(d->var, [ref])
  }

  private Void verifyHelper(Def d, Str qname, Str[] args)
  {
    verifyEq(d.typeof, HelperDef#)
    verifyEq(d->method, qname)
    args.each |arg,i|
    {
      Def p := d->params->get(i)
      if (p is LiteralDef) return verifyLiteral(p, arg)
      if (p is VarDef)     return verifyVar(p, [arg])
      throw Err()
    }
  }
}