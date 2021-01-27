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

internal const class Renderer
{
  ** Render def to 'OutStream'.
  static Void render(Def def, Str:Obj map, Str:Obj partials, OutStream out)
  {
    switch (def.typeof)
    {
      case IfDef#:
        v := resolveVar(def->var, map)
        if (isTruthy(v))
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

      case PartialDef#:
        partial := resolvePartial(def, partials)
        partial?.render(out, map, partials)

      case RawTextDef#:
        out.print(def->text)

      default:
        def.children.each |kid| { render(kid, map, partials, out) }
    }
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
      s := val.typeof.slot(n, false)
      if (s == null) { val=null; return }
      if (s is Method) val = ((Method)s).call(val)
      else val = ((Field)s).get(val)
    }
    return val
  }

  static Fanbars? resolvePartial(PartialDef def, Str:Obj partials)
  {
    partials[def.var.path[0]] as Fanbars
  }
}