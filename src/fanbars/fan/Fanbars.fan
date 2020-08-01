//
// Copyright (c) 2020, Andy Frank
// Licensed under the MIT License
//
// History:
//   30 July 2020  Andy Frank  Creation
//

*************************************************************************
** Fanbars
*************************************************************************

const class Fanbars
{
  ** Render template to a 'Str', where 'template' can be
  ** a 'Str' or a 'File'.
  static Str renderStr(Obj template, Str:Obj map)
  {
    buf := StrBuf()
    render(template, map, buf.out)
    return buf.toStr
  }

  ** Render template to given OutStream, where 'template'
  ** can be a 'Str' or a 'File'.
  static Void render(Obj template, Str:Obj map, OutStream out)
  {
    InStream? in
    try
    {
      // get our instream
      if (template is Str)  in = ((Str)template).in
      if (template is File) in = ((File)template).in
      if (in == null) throw ArgErr("Invalid 'template' argument")

      // parse and render
      def := Parser(in).parse
      Renderer.render(def, map, out)
    }
    finally { in?.close }
  }
}
