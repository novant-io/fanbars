//
// Copyright (c) 2020, Andy Frank
// Licensed under the MIT License
//
// History:
//   1 Aug 2020  Andy Frank  Creation
//

class RendererTest : Test
{

//////////////////////////////////////////////////////////////////////////
// Empty
//////////////////////////////////////////////////////////////////////////

  Void testEmpty()
  {
    m := r("", [:])
    verifyEq(m, "")
  }

//////////////////////////////////////////////////////////////////////////
// Raw
//////////////////////////////////////////////////////////////////////////

  Void testRaw()
  {
    s := "<p>Some raw text</p>"
    m := r(s, [:])
    verifyEq(m, s)
  }

//////////////////////////////////////////////////////////////////////////
// Vars
//////////////////////////////////////////////////////////////////////////

  Void testVars()
  {
    s := "{{foo}}"
    m := r(s, ["foo":"worked"])
    verifyEq(m, "worked")

    m = r(s, ["foo":12])
    verifyEq(m, "12")

    m = r(s, ["foo":true])
    verifyEq(m, "true")

    m = r(s, [:])
    verifyEq(m, "")
  }

  Void testVarsPaths()
  {
    s := "0x{{foo.toHex}}"
    m := r(s, ["foo":255])
    verifyEq(m, "0xff")

    s = "0x{{foo.first.toHex}}"
    m = r(s, ["foo":[128]])
    verifyEq(m, "0x80")

    m = r(s, [:])
    verifyEq(m, "0x")
  }

  Void testVarEscape()
  {
    s := "{{foo}}"
    m := r(s, ["foo":"< test & \""])
    verifyEq(m, "&lt; test &amp; &quot;")

    s = "{{{foo}}}"
    m = r(s, ["foo":"< test & \""])
    verifyEq(m, "< test & \"")
  }

//////////////////////////////////////////////////////////////////////////
// If
//////////////////////////////////////////////////////////////////////////

  Void testIfBasic()
  {
    s := "{{#if foo}}hello{{/if}}"
    m := r(s, ["foo":true])
    verifyEq(m, "hello")

    m = r(s, ["foo":false])
    verifyEq(m, "")

    s = "{{#if foo}}Hi {{name}}!{{/if}}"
    m = r(s, ["foo":true, "name":"Bob"])
    verifyEq(m, "Hi Bob!")
  }

//////////////////////////////////////////////////////////////////////////
// Each
//////////////////////////////////////////////////////////////////////////

  Void testEachBasic()
  {
    s := "{{#each v in items}}test,{{/each}}"
    m := r(s, [:])
    verifyEq(m, "")

    m = r(s, ["items":[1,2,3]])
    verifyEq(m, "test,test,test,")

    s = "{{#each v in items}}Item {{v}}, {{/each}}"
    m = r(s, ["items":[1,2,3]])
    verifyEq(m, "Item 1, Item 2, Item 3, ")

    s = "{{v}}, {{#each v in items}}Item {{v}}, {{/each}}{{v}}"
    m = r(s, ["v":"foo", "items":[1,2,3]])
    verifyEq(m, "foo, Item 1, Item 2, Item 3, foo")
  }

//////////////////////////////////////////////////////////////////////////
// Newlines
//////////////////////////////////////////////////////////////////////////

  Void testNewlines()
  {
    // raw text
    s := "Did
          this
          work?"
    m := r(s, [:])
    verifyEq(m, s)

    // simple var
    s = "Did
         {{foo}}
         work?"
    m = r(s, ["foo":"that"])
    verifyEq(m, "Did
                 that
                 work?")

    // simple #if
    s = "Did
         {{#if foo}}what{{/if}}
         work?"
    m = r(s, ["foo":true])
    verifyEq(m, "Did
                 what
                 work?")

    // // simple #if no-op
    // s = "Did
    //      {{#if foo}}what{{/if}}
    //      work?"
    // m = r(s, ["foo":false])
    // verifyEq(m, "Did
    //              work?")

    // // #if and eat blank lines
    // s = "Did
    //      {{#if foo}}
    //      who
    //      {{/if}}
    //      work?"
    // m = r(s, ["foo":true])
    // verifyEq(m, "Did
    //              who
    //              work?")
  }

//////////////////////////////////////////////////////////////////////////
// File
//////////////////////////////////////////////////////////////////////////

  Void testFile()
  {
    file := tempDir + `test.fb`
    file.out.print("Hello, {{name}}!").sync.close

    m := Fanbars.compile(file).renderStr(["name":"Bob"])
    verifyEq(m, "Hello, Bob!")
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  private Str r(Str template, Str:Obj map)
  {
// Parser(template.in).parse.dump(Env.cur.out, 0)
    return Fanbars.compile(template).renderStr(map)
  }
}