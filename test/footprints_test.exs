defmodule FootprintsTest do
  use ExUnit.Case
  alias Footprints.Components, as: Comps

  doctest Footprints

  test "XML" do
    # Check that we can read a defaults file and override values by reading
    # a second file...
    defaults = Footprints.Xml.read_defaults(%{}, "test/global_defaults.xml")
    assert defaults[:fabtol]            == 0.100
    assert defaults[:pinlentol]         == 0.050
    assert defaults[:toefillet]         == 0.500
    assert defaults[:heelfillet]        == 0.100
    assert defaults[:sidefillet]        == 0.000

    params = Footprints.Xml.read_defaults(defaults, "test/override_defaults.xml")
    assert params[:fabtol]            == 0.100
    assert params[:pinlentol]         == 0.050
    assert params[:toefillet]         == 1.500
    assert params[:heelfillet]        == 1.100
    assert params[:sidefillet]        == 1.000

    # Check that we can use a pip to load the defaults, then override by loading
    # the second
    params2 = Footprints.Xml.read_defaults(%{}, "test/global_defaults.xml")
              |> Footprints.Xml.read_defaults("test/override_defaults.xml")
    assert params2[:fabtol]            == 0.100
    assert params2[:pinlentol]         == 0.050
    assert params2[:toefillet]         == 1.500
    assert params2[:heelfillet]        == 1.100
    assert params2[:sidefillet]        == 1.000
  end

  test "Components" do
    line = %Comps.Line{start: {-1, 1}, end: {1, 1}, layer: "F.SilkS", width: 0.1}
    assert "#{line}" == "(fp_line (start -1.0 1.0) (end 1.0 1.0) (layer F.SilkS) (width 0.1))"

    circle = %Comps.Circle{center: {0,0}, radius: 1.1, layer: "B.SilkS", width: 0.1}
    assert "#{circle}" == "(fp_circle (center 0 0) (end 1.1 0) (layer B.SilkS) (width 0.1))"

    text = %Comps.Text{value: "Hello", location: {1,2}, layer: "F.SilkS",
                            size: {1.2,1.3}, thickness: 0.125}
    assert "#{text}" == "(fp_text user Hello (at 1.0 2.0) (layer F.SilkS) (effects (font (size 1.2 1.3) (thickness 0.125))))"

    padsmd = %Comps.PadSMD{name: "1", shape: "rect", at: {-1,1}, size: {0.1,0.2}}
    assert "#{padsmd}" == "(pad 1 smd rect (at -1.0 1.0) (size 0.1 0.2) (layers F.Cu F.Paste F.Mask))"

    padpth = %Comps.PadPTH{name: "1", shape: "rect", at: {-1,1}, size: {0.1,0.2}, drill: 1.23}
    assert "#{padpth}" == "(pad 1 thru_hole rect (at -1.0 1.0) (size 0.1 0.2) (drill 1.23) (layers *.Cu *.Mask F.SilkS))"
  end

  test "Module" do
    ref = %Comps.ReferenceText{location: {1,-1},  size: {2,3}, thickness: 0.23}
    assert "#{ref}" == "(fp_text reference REF** (at 1.0 -1.0) (layer F.Fab) (effects (font (size 2.0 3.0) (thickness 0.23))))"

    val = %Comps.ValueText{location: {1,-1},  size: {2,3}, thickness: 0.23}
    assert "#{val}" == "(fp_text value VAL** (at 1.0 -1.0) (layer F.Fab) (effects (font (size 2.0 3.0) (thickness 0.23))))"
  end

end
