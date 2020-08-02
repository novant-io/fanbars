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
        // TODO
        v := map[def->var->path->first]
        if (isTruthy(v))
          def.children.each |kid| { render(kid, map, out) }

      case VarDef#:
        // TODO
        v := map[def->path->first]
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
}