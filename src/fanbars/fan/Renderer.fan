//
// Copyright (c) 2020, Andy Frank
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
  static Void render(Def def, Str:Obj map, OutStream out)
  {
    switch (def.typeof)
    {
      case IfDef#:
        v := resolveVar(def->var, map)
        if (isTruthy(v))
          def.children.each |kid| { render(kid, map, out) }

      case EachDef#:
        List? vals:= resolveVar(def->var, map) as List
        if (vals == null) return
        iname := def->iter->path->first
        orig  := map[iname]
        vals.each |v|
        {
          map[iname] = v
          def.children.each |kid| { render(kid, map, out) }
        }
        if (orig != null) map[iname] = orig

      case VarDef#:
        v := resolveVar(def, map)
        out.print(v==null ? "" : v.toStr)

      case RawTextDef#:
        out.print(def->text)

      default:
        def.children.each |kid| { render(kid, map, out) }
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
      s := val.typeof.slot(n)
      if (s is Method) val = ((Method)s).call(val)
      else val = ((Field)s).get(val)
    }
    return val
  }
}