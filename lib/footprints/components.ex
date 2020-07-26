defmodule Footprints.Components do


    @doc """
    Rounds a float to the specified number of digits.

    ## Parameters
        - x:   Float value to be rounded
        - dig: Number of digits (after the decimal) to round to

    ## Yields
        Float value of input x rounded to the specified digits

    ## Examples
        iex> Footprints.Components.p(1.234567890123)
        1.235

        iex> Footprints.Components.p(1.234567890123, 4)
        1.2346
    """
    def p(x, dig \\ 3), do: Float.round(x / 1.0, dig)


    @doc """
    Creates a KiCad footprint circle of the specified size at the given location.

    ## Parameters
        - center: Float location {xc, yc} of the circle center (x,y in KiCad units)
        - radius: Float radius of the circle (in KiCad units)
        - layer:  String describing the layer the circle is placed on (KiCad layer name)

    ## Yields
        String representation of KiCad footprint circle

    ## Examples
        iex> Footprints.Components.circle({0,0}, 1.1, "B.SilkS", 0.1)
        "(fp_circle (center 0.0 0.0) (end 1.1 0.0) (layer B.SilkS) (width 0.1))"

        iex> Footprints.Components.circle({-1.1,2.2}, 3.3, "F.SilkS", 0.05)
        "(fp_circle (center -1.1 2.2) (end 2.2 2.2) (layer F.SilkS) (width 0.05))"
    """
    def circle({xc, yc}, r, layer, width) do
        "(fp_circle" <>
        " (center #{p(xc)} #{p(yc)})" <>
        " (end #{p(xc + r)} #{p(yc)})" <>
        " (layer #{layer}) (width #{width})" <>
        ")"
    end


    @doc """
    Creates a KiCad footprint line at the specified start/end location.

    ## Parameters
        - start: Float start location {x, y} of the line (x,y in KiCad units)
        - end:   Float ending location {x, y} of the line (x,y in KiCad units)
        - layer: String describing the layer the circle is placed on (KiCad layer name)
        - width: Float drawing width of the line (in KiCad units)

    ## Yields
        String representation of KiCad footprint line

    ## Examples
        iex> Footprints.Components.line({0,0}, {1.1,1.1}, "F.SilkS", 0.1)
        "(fp_line (start 0.0 0.0) (end 1.1 1.1) (layer F.SilkS) (width 0.1))"
    """
    def line({xs, ys}, {xe, ye}, lay, wid) do
        "(fp_line" <>
        " (start #{p(xs)} #{p(ys)})" <>
        " (end #{p(xe)} #{p(ye)})" <>
        " (layer #{lay}) (width #{wid})" <>
        ")"
    end


    @doc """
    Creates a KiCad footprint rectangular box at the specified location.

    ## Parameters
        - ll:    Float location {x, y} of the lower-left corner (x,y in KiCad units)
        - ur:    Float location {x, y} of the upper-right corner (x,y in KiCad units)
        - layer: String describing the layer the circle is placed on (KiCad layer name)
        - width: Float drawing width of the line (in KiCad units)

    ## Yields
        List of string representations of KiCad footprint lines forming the specified box

    ## Examples
        iex> Footprints.Components.box({0,0}, {1.1,1.1}, "B.SilkS", 0.1)
        ["(fp_line (start 0.0 0.0) (end 1.1 0.0) (layer B.SilkS) (width 0.1))", "(fp_line (start 1.1 0.0) (end 1.1 1.1) (layer B.SilkS) (width 0.1))", "(fp_line (start 1.1 1.1) (end 0.0 1.1) (layer B.SilkS) (width 0.1))", "(fp_line (start 0.0 1.1) (end 0.0 0.0) (layer B.SilkS) (width 0.1))"]
    """
    def box({llx, lly}, {urx, ury}, layer, width) do
        [line({llx, lly}, {urx, lly}, layer, width),
         line({urx, lly}, {urx, ury}, layer, width),
         line({urx, ury}, {llx, ury}, layer, width),
         line({llx, ury}, {llx, lly}, layer, width)]
    end

  @doc """
    Creates a KiCad footprint arc at the specified location.

    ## Parameters
      - start: Float start location {x, y} of the arc (x,y in KiCad units)
      - end:   Float ending location {x, y} of the arc (x,y in KiCad units)
      - angle: Float angle subtended by the arc
      - layer: String describing the layer the circle is placed on (KiCad layer name)
      - width: Float drawing width of the arc (in KiCad units)

    ## Yields
      String representation of KiCad footprint line

    ## Examples
        iex> Footprints.Components.arc(start: {0,0}, end: {1.1,1.1}, angle: 90, layer: "F.SilkS", width: 0.1)
        "(fp_arc  (start 0.0 0.0) (end 1.1 1.1) (angle 90.0) (layer F.SilkS) (width 0.1))"
  """
  def arc(start: {xs, ys}, end: {xe, ye}, angle: angle, layer: lay, width: wid) do
    "(fp_arc " <>
    " (start #{p(xs)} #{p(ys)})" <>
    " (end #{p(xe)} #{p(ye)})" <>
    " (angle #{p(angle)})" <>
    " (layer #{lay})" <>
    " (width #{wid})" <>
    ")"
  end

  
    defp textGeneric(type, value, {x, y}, angle, layer, {xs, ys}, wid) do
        "(fp_text #{type} #{value}" <>
        " (at #{p(x)} #{p(y)} #{p(angle)})" <>
        " (layer #{layer}) " <>
        " (effects (font (size #{p(xs)} #{p(ys)}) (thickness #{wid})))" <>
        ")"
    end


    @doc """
    Creates KiCad footprint text at the specified location.

    ## Parameters
        - value: String to be printed/placed
        - at:    Float location {x, y} of the text (x,y in KiCad units)
        - angle: Float angle of the text, in degrees
        - layer: String describing the layer the circle is placed on (KiCad layer name)
        - size:  Float size {x,y} of a character of text in the x and y directions
        - width: Float drawing width of the arc (in KiCad units)

    ## Yields
        String representation of KiCad footprint text

    ## Examples
        iex> Footprints.Components.text("Junk", {0,0}, 90, "F.SilkS", {1,1}, 0.1)
        "(fp_text user Junk (at 0.0 0.0 90.0) (layer F.SilkS)  (effects (font (size 1.0 1.0) (thickness 0.1))))"
    """
    def text(value, at, angle, layer, size, width) do
        textGeneric("user", value, at, angle, layer, size, width)
    end


    @doc """
    Creates KiCad footprint component reference text at the specified location.

    ## Parameters
    - at:    Float location {x, y} of the text (x,y in KiCad units)
    - angle: Float angle of the text, in degrees
    - size:  Float size {x,y} of a character of text in the x and y directions
    - width: Float drawing width of the arc (in KiCad units)

    ## Yields
    String representation of KiCad footprint text

    ## Examples
        iex> Footprints.Components.textRef({0,0}, 90, {1,1}, 0.1)
        "(fp_text reference REF** (at 0.0 0.0 90.0) (layer F.SilkS)  (effects (font (size 1.0 1.0) (thickness 0.1))))"
    """
    def textRef(at, angle, size, width) do
        textGeneric("reference", "REF**", at, angle, "F.SilkS", size, width)
    end


    @doc """
    Creates KiCad footprint component value text at the specified location.

    ## Parameters
        - at:    Float location {x, y} of the text (x,y in KiCad units)
        - angle: Float angle of the text, in degrees
        - size:  Float size {x,y} of a character of text in the x and y directions
        - width: Float drawing width of the arc (in KiCad units)

    ## Yields
        String representation of KiCad footprint text

    ## Examples
        iex> Footprints.Components.textVal({0,0}, 90, {1,1}, 0.1)
        "(fp_text value VAL** (at 0.0 0.0 90.0) (layer F.Fab)  (effects (font (size 1.0 1.0) (thickness 0.1))))"
    """
    def textVal(at, angle, size, width) do
        textGeneric("value", "VAL**", at, angle, "F.Fab", size, width)
    end


    @doc """
    Creates KiCad footprint pad at the specified location.

    ## Parameters
        - name:        String description/name for the pad
        - shape:       String describing the shape of the pad (rect, roundrect, circle)
        - at:          Float location {x, y} of the text (x,y in KiCad units)
        - size:        Float size {x,y} of a character of text in the x and y directions
        - pastemargin: The value to use for the pad solder_paste_margin_ratio value
        - maskmargin:  The value to use for the pad solder_mask_margin value

    ## Yields
        String representation of KiCad footprint pad

    ## Examples
        iex> Footprints.Components.pad(:smd, "A", "rect", {0,0}, {1,1}, 0, 0)
        "(pad A smd rect (at 0.0 0.0) (size 1.0 1.0) (clearance 0.1) (layers F.Cu) (solder_paste_margin_ratio 0) (solder_mask_margin 0))"

        iex> Footprints.Components.pad(:pth, "A", "circle", {0,0}, {1,1}, 0, 0)
        "(pad A thru_hole circle (at 0.0 0.0) (size 1.0 1.0) (drill 0) (layers *.Cu) (solder_mask_margin 0))"
    """
    def pad(type, name, shape, at, size, pastemargin \\ 0, maskmargin \\ 0)
    def pad(:smd, name, shape, {x, y}, {xs, ys}, pastemargin, maskmargin) do
        "(pad #{name} smd #{shape}" <>
        " (at #{p(x)} #{p(y)})" <>
        " (size #{p(xs)} #{p(ys)})" <>
        " (clearance 0.1)" <>
        " (layers F.Cu F.Mask F.Paste)" <>
        " (solder_paste_margin_ratio #{pastemargin})" <>
        " (solder_mask_margin #{maskmargin})" <>
        ")"
    end
    def pad(:pth, name, shape, {x, y}, {xs, ys}, drilldia, maskmargin) do
        "(pad #{name} thru_hole #{shape}" <>
        " (at #{p(x)} #{p(y)})" <>
        " (size #{p(xs)} #{p(ys)})" <>
        " (drill #{drilldia})" <>
        " (layers *.Cu F.Mask B.Mask)" <>
        " (solder_mask_margin #{maskmargin})" <>
        ")"
    end


    @doc """
    Creates a KiCad footprint modules with the provided parameters and features.

    ## Parameters
        - name:      String description/name for the module
        - descr:     String (text) description of the module
        - features:  List of "features" (Footprints.Components as Strings)
        - refAt:     Float location {x, y} of the reference text (x,y in KiCad units)
        - valAt:     Float location {x,y} of a value text (x,y in KiCad units)
        - tags:      List of Strings for module tags
        - isSMD:     Boolean identifying the module as surface mount

    ## Yields
        String representation of KiCad footprint module
    """
    def module(name, descr, features, refAt, valAt, textsize, textwidth, tags \\ []) do
        ref = textRef(refAt, 90, textsize, textwidth)
        val = textVal(valAt, 90, textsize, textwidth)
        edittime = Integer.to_string(:os.system_time(:seconds), 16)

        "(module #{name} (layer F.Cu) (tedit #{edittime})\n" <>
        "  (at 0 0)\n" <>
        "  (descr \"#{descr}\")\n" <>
        "  (tags \"" <> Enum.join(Enum.map(tags, fn a -> "#{a}" end), " ") <> "\")\n" <>
        "  #{ref}\n" <>
        "  #{val}\n" <>
        Enum.join(Enum.map(features, fn a -> "#{a}" end), "\n  ") <>
        ")"
    end

end
