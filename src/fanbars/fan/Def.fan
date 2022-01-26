//
// Copyright (c) 2020, Novant LLC
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
    out.printLine("#if '${var.dumpPath}'")
    children.each |k| { k.dump(out, indent+2) }
    out.print(Str.spaces(indent)).printLine("/if")
  }
}

*************************************************************************
** IfNotDef
*************************************************************************

internal class IfNotDef : Def
{
  new make(|This| f) { f(this) }

  VarDef var

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.printLine("#ifnot '${var.dumpPath}'")
    children.each |k| { k.dump(out, indent+2) }
    out.print(Str.spaces(indent)).printLine("/ifnot")
  }
}

*************************************************************************
** EachDef
*************************************************************************

internal class EachDef : Def
{
  new make(|This| f) { f(this) }

  VarDef iter
  VarDef var

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.printLine("#each '${iter.dumpPath}' in '${var.dumpPath}'")
    children.each |k| { k.dump(out, indent+2) }
    out.print(Str.spaces(indent)).printLine("/each")
  }
}

*************************************************************************
** VarDef
*************************************************************************

internal class VarDef : Def
{
  new make(|This| f) { f(this) }

  const Str[] path
  const Bool escape := true

  Str dumpPath() { path.join(".") }

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.printLine("var '${dumpPath}'")
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

*************************************************************************
** GenDef
*************************************************************************

internal class GenDef : Def
{
  new make(|This| f) { f(this) }

  VarDef func

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.printLine("{{#gen $func.dumpPath")
  }
}

*************************************************************************
** PartialDef
*************************************************************************

internal class PartialDef : Def
{
  new make(|This| f) { f(this) }

  VarDef var

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.printLine("{{#partial $var.dumpPath")
  }
}