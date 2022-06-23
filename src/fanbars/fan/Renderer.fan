//
// Copyright (c) 2020, Novant LLC
// Licensed under the MIT License
//
// History:
//   1 Aug 2020  Andy Frank  Creation
//

*************************************************************************
** Renderer
*************************************************************************

@Js internal const class Renderer
{
  ** Render def to 'OutStream'.
  static Void render(Def def, Str:Obj map, Obj? partials, OutStream out)
  {
    switch (def.typeof)
    {
      case IfDef#:
        v := resolveVar(def->var, map)
        if (eval(v, def->op, def->rhs))
          def.children.each |kid| { render(kid, map, partials, out) }

      case IfNotDef#:
        v := resolveVar(def->var, map)
        if (!isTruthy(v))
          def.children.each |kid| { render(kid, map, partials, out) }

      case EachDef#:
        List? vals:= resolveVar(def->var, map) as List
        if (vals == null) return
        iname := def->iter->path->first
        orig  := map[iname]
        vals.each |v|
        {
          if (v != null) map[iname] = v
          def.children.each |kid| { render(kid, map, partials, out) }
        }
        if (orig != null) map[iname] = orig
        else map.remove(iname)

      case VarDef#:
        v := resolveVar(def, map)
        if (def->escape == true)
          out.writeXml(v==null ? "" : v.toStr, OutStream.xmlEscQuotes)
        else
          out.print(v==null ? "" : v.toStr)

      case GenDef#:
        f := resolveVar(def->func, map) as Func
        if (f == null) return
        f(out)

      case PartialDef#:
        partial := resolvePartial(def, partials)
        partial?.render(out, map, partials)

      case RawTextDef#:
        out.print(def->text)

      default:
        def.children.each |kid| { render(kid, map, partials, out) }
    }
  }

  ** Evalue value to 'true' if 'val' equals 'rhs', or if 'rhs'
  ** is null, then 'isTruthy(val)'.
  static Bool eval(Obj? val, Str? op := null, LiteralDef? rhs := null)
  {
    // short-circuit if no rhs
    if (rhs == null) return isTruthy(val)

    // check op for comparison
    if (op == "is")    return val?.toStr == rhs.val
    if (op == "isnot") return val?.toStr != rhs.val
    return false
  }

  ** Return if we should treat given value as 'true'.
  static Bool isTruthy(Obj? val)
  {
    if (val == null) return false
    if (val == false) return false
    // TODO: what else?
    return true
  }

  ** Resolve a VarDef to a map value.
  static Obj? resolveVar(VarDef def, Str:Obj map)
  {
    val := map[def.path.first]
    def.path.eachRange(1..-1) |n|
    {
      if (val == null) return
      if (val is Map)
      {
        Map m := val
        if (m.containsKey(n)) { val=m[n]; return }
      }
      try { val = val.trap(n) }
      catch { val = null }
    }
    return val
  }

  static Fanbars? resolvePartial(PartialDef def, Obj? partials)
  {
    if (partials == null) return null

    name := def.var.path[0]
    if (partials is Map)  return ((Map)partials)[name] as Fanbars
    if (partials is Func) return ((Func)partials)(name) as Fanbars
    throw ArgErr("Invalid partials argument: ${partials}")
  }
}