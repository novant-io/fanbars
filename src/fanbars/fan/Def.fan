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

@Js internal class Def
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
** LiteralDef
*************************************************************************

@Js internal class LiteralDef : Def
{
  new make(|This| f) { f(this) }

  const Str val

  Str dumpVal() { "'${val}'" }

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.printLine(dumpVal)
  }
}

*************************************************************************
** IfDef
*************************************************************************

@Js internal class IfDef : Def
{
  new make(|This| f) { f(this) }

  VarDef var
  const Str? op
  LiteralDef? rhs

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.print("#if '${var.dumpPath}'")
    if (rhs != null) out.print(" ${op} ${rhs.dumpVal}")
    out.printLine("")
    children.each |k| { k.dump(out, indent+2) }
    out.print(Str.spaces(indent)).printLine("/if")
  }
}

*************************************************************************
** IfNotDef
*************************************************************************

@Js internal class IfNotDef : Def
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

@Js internal class EachDef : Def
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

@Js internal class VarDef : Def
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

@Js internal class RawTextDef : Def
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

@Js internal class GenDef : Def
{
  new make(|This| f) { f(this) }

  VarDef func

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.printLine("#gen $func.dumpPath")
  }
}

*************************************************************************
** PartialDef
*************************************************************************

@Js internal class PartialDef : Def
{
  new make(|This| f) { f(this) }

  VarDef var

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.printLine("#partial $var.dumpPath")
  }
}

*************************************************************************
** HelperDef
*************************************************************************

@Js internal class HelperDef : Def
{
  new make(|This| f) { f(this) }

  const Str method
  Def[] params

  override Void dump(OutStream out, Int indent)
  {
    out.print(Str.spaces(indent))
    out.print("#helper $method")
    params.each |p| { out.print(" ").print(p is VarDef ? p->dumpPath : p->dumpVal) }
    out.printLine("")
  }
}