//
// Copyright (c) 2020, Andy Frank
// Licensed under the MIT License
//
// History:
//   31 July 2020  Andy Frank  Creation
//

*************************************************************************
** Def
*************************************************************************

internal class Def
{
  ** Child nodes for this AST node.
  Def[] children := [,]

  // TODO
  // Loc loc { file, line }

  ** Dump AST to given outsteam.
  virtual Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.printLine("def")
    children.each |k| { k.dump(out, indent+2) }
  }
}

*************************************************************************
** IfDef
*************************************************************************

internal class IfDef : Def
{
  new make(|This| f) { f(this) }

  VarDef var

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.printLine("#if '${var.name}'")
    children.each |k| { k.dump(out, indent+2) }
    out.print(Str.spaces(indent)).printLine("/if")
  }
}

*************************************************************************
** VarDef
*************************************************************************

internal class VarDef : Def
{
  new make(|This| f) { f(this) }

  const Str name

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.printLine("var ${name.toCode}")
  }
}

*************************************************************************
** RawTextDef
*************************************************************************

internal class RawTextDef : Def
{
  new make(|This| f) { f(this) }

  const Str text

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.printLine("raw ${text.toCode}")
  }
}
