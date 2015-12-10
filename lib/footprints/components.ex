
defmodule Footprints.Components do

  defmodule Circle do
    defstruct center: nil, radius: nil, layer: nil, width: nil

    defimpl String.Chars, for: Circle do
      def to_string( %Circle{center: {xc,yc}, radius: r, layer: layer, width: wid} ) do
        "(fp_circle (center #{xc} #{yc}) (end #{xc+r} #{yc}) (layer #{layer}) (width #{wid}))"
      end
    end

  end

  defmodule Line do
    defstruct start: nil, end: nil, layer: nil, width: nil

    defimpl String.Chars, for: Line do
      def pp(x), do: Float.round(x/1.0,3)
      def to_string( %Line{start: {xs,ys}, end: {xe,ye}, layer: layer, width: wid} ) do
        "(fp_line (start #{pp(xs)} #{pp(ys)}) (end #{pp(xe)} #{pp(ye)}) (layer #{layer}) (width #{wid}))"
      end
    end

  end

  defmodule Text do
    defstruct value: "", location: nil, layer: nil, size: nil, thickness: nil

    defimpl String.Chars, for: Text do
      def pp(x), do: Float.round(x/1.0,3)
      def to_string( %Text{value: value, location: {x,y,a}, layer: layer, size: {xs,ys}, thickness: thick} ) do
        "(fp_text user #{value} (at #{pp(x)} #{pp(y)} #{pp(a)}) (layer #{layer}) " <>
        "(effects (font (size #{pp(xs)} #{pp(ys)}) (thickness #{thick}))))"
      end
      def to_string( %Text{value: value, location: {x,y}, layer: layer, size: {xs,ys}, thickness: thick} ) do
        "(fp_text user #{value} (at #{pp(x)} #{pp(y)}) (layer #{layer}) " <>
        "(effects (font (size #{pp(xs)} #{pp(ys)}) (thickness #{thick}))))"
      end
    end

  end


  defmodule PadSMD do
    # Layers are fixed for SMD pads
    defstruct name: "", shape: nil, at: nil, size: nil

    defimpl String.Chars, for: PadSMD do
      def pp(x), do: Float.round(x/1.0,3)
      def to_string( %PadSMD{name: name, shape: shape, at: {x,y}, size: {xs,ys}} ) do
        "(pad #{name} smd #{shape} (at #{pp(x)} #{pp(y)}) (size #{pp(xs)} #{pp(ys)}) (layers F.Cu F.Paste F.Mask))"
      end
    end
  end

  defmodule PadPTH do
    # Layers are fixed for thru-hole pads
    defstruct name: "", shape: nil, at: nil, size: nil, drill: nil

    defimpl String.Chars, for: PadPTH do
      def pp(x), do: Float.round(x/1.0,3)
      def to_string( %PadPTH{name: name, shape: shape, at: {x,y}, size: {xs,ys}, drill: drill} ) do
        "(pad #{name} thru_hole #{shape} (at #{pp(x)} #{pp(y)}) (size #{pp(xs)} #{pp(ys)}) (drill #{drill}) (layers *.Cu *.Mask F.SilkS))"
      end
    end
  end



  defmodule ReferenceText do
    defstruct location: nil, size: nil, thickness: nil

    defimpl String.Chars, for: ReferenceText do
      def pp(x), do: Float.round(x/1.0,3)
      def to_string( %ReferenceText{location: {x,y,a},  size: {xs,ys}, thickness: thick} ) do
        "(fp_text reference REF** (at #{pp(x)} #{pp(y)} #{pp(a)}) (layer F.Fab) " <>
        "(effects (font (size #{pp(xs)} #{pp(ys)}) (thickness #{thick}))))"
      end
      def to_string( %ReferenceText{location: {x,y},  size: {xs,ys}, thickness: thick} ) do
        "(fp_text reference REF** (at #{pp(x)} #{pp(y)}) (layer F.Fab) " <>
        "(effects (font (size #{pp(xs)} #{pp(ys)}) (thickness #{thick}))))"
      end
    end

  end

  defmodule ValueText do
    defstruct location: nil, size: nil, thickness: nil

    defimpl String.Chars, for: ValueText do
      def pp(x), do: Float.round(x/1.0,3)
      def to_string( %ValueText{location: {x,y,a}, size: {xs,ys}, thickness: thick} ) do
        "(fp_text value VAL** (at #{pp(x)} #{pp(y)} #{pp(a)}) (layer F.Fab) " <>
        "(effects (font (size #{pp(xs)} #{pp(ys)}) (thickness #{thick}))))"
      end
      def to_string( %ValueText{location: {x,y}, size: {xs,ys}, thickness: thick} ) do
        "(fp_text value VAL** (at #{pp(x)} #{pp(y)}) (layer F.Fab) " <>
        "(effects (font (size #{pp(xs)} #{pp(ys)}) (thickness #{thick}))))"
      end
    end

  end


  defmodule Module do
    # Location fixed at {0,0}, layer fixed at "F.Cu"
    defstruct name: "", reflocation: nil, valuelocation: nil, textsize: nil, textwidth: nil,
              descr: "", tags: nil, isSMD: false, features: nil

    defimpl String.Chars, for: Module do
      def to_string( %Module{name: name,
                             reflocation: {xr,yr,a},
                             valuelocation: {xv,yv,a},
                             textsize: {xs,ys}, textwidth: wid,
                             descr: descr,
                             tags: tags, isSMD: smd, features: features} ) do

        ref = %ReferenceText{location: {xr,yr,a}, size: {xs,ys}, thickness: wid}
        val = %ValueText{location: {xv,yv,a},size: {xs,ys}, thickness: wid}
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
    end
  end
end
