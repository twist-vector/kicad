
defmodule Footprints.Components do


  defp p(x), do: Float.round(x/1.0,3)

  def circle(center: {xc,yc}, radius: r, layer: lay, width: wid), do:
    "(fp_circle (center #{p(xc)} #{p(yc)}) (end #{p(xc+r)} #{p(yc)}) (layer #{lay}) (width #{wid}))"

  def line(start: {xs,ys}, end: {xe,ye}, layer: lay, width: wid), do:
    "(fp_line (start #{p(xs)} #{p(ys)}) (end #{p(xe)} #{p(ye)}) (layer #{lay}) (width #{wid}))"


  def textGeneric(type: type, value: value, at: {x,y,a}, layer: lay, size: {xs,ys}, width: wid), do:
    "(fp_text #{type} #{value} (at #{p(x)} #{p(y)} #{p(a)}) (layer #{lay}) " <>
    "(effects (font (size #{p(xs)} #{p(ys)}) (thickness #{wid})))" <>
    ")"

  def text(value, at: at={_x,_y,_a}, layer: lay, size: s={_xs,_ys}, width: wid), do:
    textGeneric(type: "user", value: value, at: at, layer: lay, size: s, width: wid)

  def textRef(at: at={_x,_y,_a}, size: s={_xs,_ys}, width: wid), do:
    textGeneric(type: "reference", value: "REF**", at: at, layer: "F.SilkS", size: s, width: wid)

  def textVal(at: at={_x,_y,_a}, size: size={_xs,_ys}, width: wid), do:
    textGeneric(type: "value", value: "VAL**", at: at, layer: "F.SilkS", size: size, width: wid)


  def pad(name: name, type: type, shape: shape, at: {x,y}, size: {xs,ys}, layers: layers) do
    "(pad #{name} #{type} #{shape} (at #{p(x)} #{p(y)}) (size #{p(xs)} #{p(ys)})" <>
    " (layers " <>
    Enum.join(layers, " ") <> "))"
  end

  def padSMD(name: name, shape: shape, at: {x,y}, size: {xs,ys}), do:
     pad(name: name, type: "smd", shape: shape, at: {x,y},
         size: {xs,ys}, layers: ["F.Cu", "F.Paste", "F.Mask"])

  def padPTH(name: name, shape: shape, at: {x,y}, size: {xs,ys}, drill: drill), do:
     "(pad #{name} thru_hole #{shape} (at #{p(x)} #{p(y)}) " <>
     "(size #{p(xs)} #{p(ys)}) (drill #{drill}) (layers *.Cu *.Mask F.SilkS))"

  def module(name: name,
             valuelocation: refAt = {_xr,_yr,_ar},
             referencelocation: valAt = {_xv,_yv,_av},
             textsize: size={_xs,_ys},
             textwidth: wid,
             descr: descr,
             tags: tags,
             isSMD: smd,
             features: features) do
    ref = textRef(at: refAt, size: size, width: wid)
    val = textVal(at: valAt, size: size, width: wid)
    edittime = Integer.to_string(:os.system_time(:seconds),16)
    "(module #{name} (layer F.Cu) (tedit #{edittime})\n" <>
    "  (at 0 0)\n" <>
    "  (descr \"#{descr}\")\n" <>
    "  (tags \"" <> Enum.join( Enum.map(tags, fn a -> "#{a}" end), " " ) <> "\")\n" <>
    if smd, do: "  (attr smd)\n", else: "" <>
    "  #{ref}\n" <>
    "  #{val}\n" <>
    "  " <> Enum.join( Enum.map(features, fn a -> "#{a}" end), "\n  " ) <> "\n" <>
    ")"
  end


  def box(ll: ll={llx,lly}, ur: ur={urx,ury}, layer: layer, width: thick) do
    [line(start:         ll, end: {urx, lly}, layer: layer, width: thick),
     line(start: {urx, lly}, end:         ur, layer: layer, width: thick),
     line(start:         ur, end: {llx, ury}, layer: layer, width: thick),
     line(start: {llx, ury}, end:         ll, layer: layer, width: thick)]
  end



end
