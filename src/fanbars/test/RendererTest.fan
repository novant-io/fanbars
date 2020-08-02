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
// File
//////////////////////////////////////////////////////////////////////////

  Void testFile()
  {
    file := tempDir + `test.fb`
    file.out.print("Hello, {{name}}!").sync.close

    m := Fanbars.renderStr(file, ["name":"Bob"])
    verifyEq(m, "Hello, Bob!")
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  private Str r(Str template, Str:Obj map)
  {
    Fanbars.renderStr(template, map)
  }
}