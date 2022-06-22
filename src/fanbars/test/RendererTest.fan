//
// Copyright (c) 2020, Novant LLC
// Licensed under the MIT License
//
// History:
//   1 Aug 2020  Andy Frank  Creation
//

@Js class RendererTest : Test
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

    s = "0x{{foo.first.toHex.doesNotExist}}"
    m = r(s, ["foo":[128]])
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

  Void testVarUnicode()
  {
    s := "70°F == {{foo}}"
    m := r(s, ["foo":"21°C"])
    verifyEq(m, "70°F == 21°C")
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

  Void testIfNotBasic()
  {
    s := "{{#ifnot foo}}hello{{/ifnot}}"
    m := r(s, ["foo":true])
    verifyEq(m, "")

    m = r(s, ["foo":false])
    verifyEq(m, "hello")

    s = "{{#ifnot foo}}Hi {{name}}!{{/ifnot}}"
    m = r(s, ["foo":false, "name":"Bob"])
    verifyEq(m, "Hi Bob!")
  }

  Void testIfComplex()
  {
    s := "{{#if foo}}foo{{/if}}{{#ifnot foo}}bar{{/ifnot}}"
    verifyEq(r(s,["foo":true]),  "foo")
    verifyEq(r(s,["foo":false]), "bar")
  }

  Void testIfIs()
  {
    s := "{{#if foo is 'xyz'}}hello{{/if}}"
    m := r(s, ["foo":"xyz"])
    verifyEq(m, "hello")

    m = r(s, ["foo":"abc"])
    verifyEq(m, "")

    m = r(s, ["foo":null])
    verifyEq(m, "")

    s = "{{#if foo is '123'}}Hi {{name}}!{{/if}}"
    m = r(s, ["foo":123, "name":"Bob"])
    verifyEq(m, "Hi Bob!")

    s = "{{#if foo isnot 'xyz'}}hello{{/if}}"
    m = r(s, ["foo":"xyz"])
    verifyEq(m, "")
    m = r(s, ["foo":"abc"])
    verifyEq(m, "hello")
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

  Void testEachVarPath()
  {
    s := "{{#each v in items}}{{v.name}} is {{v.price}} [{{v.size}}], {{/each}}"
    m := r(s, [:])
    verifyEq(m, "")

    m = r(s, ["items":[
      ["name":"Alpha", "price":45],
      ["name":"Beta",  "price":60, "foo":true],
      ["name":"Gamma", "price":17, "foo":true, "bar":0],
    ]])
    verifyEq(m, "Alpha is 45 [2], Beta is 60 [3], Gamma is 17 [4], ")
  }

  Void testEachVarLeak()
  {
    s := """{{#each v in items}}{{v.name}}{{/each}}{{#if v}}I should not see this{{/if}}"""
    m := r(s, ["items":[
      ["name":"foo"],
    ]])
    verifyEq("foo", m)
  }

//////////////////////////////////////////////////////////////////////////
// Complex
//////////////////////////////////////////////////////////////////////////

  Void testComplex()
  {
    s := "{{#each row in rows}}
            <tr>
            {{#each item in row}}
              <td>
                {{#if item.isNaN}}?{{/if}}
                {{#ifnot item.isNaN}}{{item}}{{/ifnot}}
              </td>
            {{/each}}
            </tr>
          {{/each}}".splitLines.join("") |s| { s.trim }

    m := [
      "rows":[
        [1,Float.nan,3],
        [4,5,Float.nan],
      ]
    ]

    t := r(s,m)
    verifyEq(t, "<tr><td>1</td><td>?</td><td>3</td></tr>" +
                "<tr><td>4</td><td>5</td><td>?</td></tr>")
  }

//////////////////////////////////////////////////////////////////////////
// Gen
//////////////////////////////////////////////////////////////////////////

  Void testGen()
  {
    m := ["f1": |OutStream out| { out.print("from generator") }]
    s := "{{#gen f1}}"
    t := r(s,m)
    verifyEq(t, "from generator")

    // test closure
    x  := 12
    y  := "foo"
    f2 := |OutStream out| {
      out.print("from generator, where x is ${x} and y is ${y}")
    }
    m = ["f2":f2]
    s = "{{#gen f2}}"
    t = r(s,m)
    verifyEq(t, "from generator, where x is 12 and y is foo")
  }

//////////////////////////////////////////////////////////////////////////
// Partials
//////////////////////////////////////////////////////////////////////////

  Void testPartials()
  {
    p := [
      "raw": Fanbars.compile("Raw Partial"),
      "var": Fanbars.compile("Hello {{user}}!"),
    ]

    // new syntax
    m := ["user": "Kvoth"]
    s := "{{#partial raw}}
          {{#partial var}}"
    t := r(s,m,p)
    verifyEq(t, "Raw Partial
                 Hello Kvoth!")
  }

//////////////////////////////////////////////////////////////////////////
// Comments
//////////////////////////////////////////////////////////////////////////

 Void testComments()
  {
    s := "{{!-- this is comment --}}Hello, {{name}}"
    m := r(s, ["name":"World"])
    verifyEq(m, "Hello, World")
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
    if (Env.cur.runtime == "js") return

    file := tempDir + `test.fb`
    file.out.print("Hello, {{name}}!").sync.close

    m := Fanbars.compile(file).renderStr(["name":"Bob"])
    verifyEq(m, "Hello, Bob!")
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  private Str r(Str template, Str:Obj map, Str:Obj partials := [:])
  {
// Parser(template.in).parse.dump(Env.cur.out, 0)
    return Fanbars.compile(template).renderStr(map, partials)
  }
}