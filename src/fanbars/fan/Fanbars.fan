//
// Copyright (c) 2020, Andy Frank
// Licensed under the MIT License
//
// History:
//   30 July 2020  Andy Frank  Creation
//

using concurrent

*************************************************************************
** Fanbars
*************************************************************************

const class Fanbars
{
  ** Compile the template into a 'Fanbars' instance, where
  ** 'template' can be an 'InStream', 'Str', or 'File'.
  static new compile(Obj template)
  {
    InStream? in := template as InStream
    try
    {
      // get our instream
      if (template is Str)  in = ((Str)template).in
      if (template is File) in = ((File)template).in
      if (in  == null) throw ArgErr("Invalid 'template' argument")

      // parse template an return instance
      def := Parser(in).parse
      return Fanbars { it.defRef = AtomicRef(Unsafe(def)) }
    }
    finally { in?.close }
  }

  ** Render template to a 'Str' instancce.
  Str renderStr(Str:Obj map)
  {
    buf := StrBuf()
    render(buf.out, map)
    return buf.toStr
  }

  ** Render template to given OutStream.
  Void render(OutStream out, Str:Obj map)
  {
    def := (defRef.val as Unsafe).val
    Renderer.render(def, map, out)
  }

  ** Private ctor.
  private new make(|This| f) { f(this) }

  // TODO FIXIT: until we can get our AST to be const :(
  private const AtomicRef defRef
}
