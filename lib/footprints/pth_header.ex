defmodule Footprints.PTHHeader do
  alias Footprints.Components, as: Comps


  def make_outline(pinpitch, i, layer, {xc,yc}) do
    numpoints  = 8
    angle      = 22.5 * :math.pi / 180.0

    bodyrad    = pinpitch / :math.cos(22.5 * :math.pi / 180.0) / 2.0;
    thetaStart = i*2.0*:math.pi/numpoints + angle
    thetaEnd   = (i+1)*2.0*:math.pi/numpoints + angle
    dxStart    = bodyrad * :math.cos(thetaStart)
    dyStart    = bodyrad * :math.sin(thetaStart)
    dxEnd      = bodyrad * :math.cos(thetaEnd)
    dyEnd      = bodyrad * :math.sin(thetaEnd)
    %Comps.Line{start: {xc+dxStart,yc+dyStart}, end: {xc+dxEnd,yc+dyEnd}, layer: layer, width: 0.1}
  end


  def make_box(len, wid, layer, thick) do
    [%Comps.Line{start: {-len, wid}, end: { len, wid}, layer: layer, width: thick},
     %Comps.Line{start: {-len,-wid}, end: { len,-wid}, layer: layer, width: thick},
     %Comps.Line{start: { len,-wid}, end: { len, wid}, layer: layer, width: thick},
     %Comps.Line{start: {-len,-wid}, end: {-len, wid}, layer: layer, width: thick}]
  end


  def make_pad(params, pin, row, pincount, rowcount) do
    pinpitch        = params[:pinpitch]
    rowpitch        = params[:rowpitch]
    padwidth        = params[:padwidth]
    padheight       = params[:padheight]
    drilldia        = params[:drilldia]

    bodylen   = pinpitch * (pincount - 1) + padwidth
    bodywid   = rowpitch * (rowcount - 1) + padheight;
    totallen  = bodylen
    totalwid  = bodywid

    xc = -((pincount-1)/2*pinpitch) + (pin-1)*pinpitch
    yc = rowpitch*(rowcount-1)/2.0 - row*rowpitch
    pn = (pin-1)*rowcount + row + 1#pin + (row)*pincount

    frontSilkBorder = for n <- 0..7, do: make_outline(pinpitch, n,"F.SilkS",{xc,yc})
    backSilkBorder  = for n <- 0..7, do: make_outline(pinpitch, n,"B.SilkS",{xc,yc})

    p = %Comps.PadPTH{name: "#{pn}", shape: "oval", at: {xc,yc},
           size: {padwidth,padheight}, drill: drilldia}

    xcc = totallen/2 + padwidth/4
    ycc = totalwid/2 + padheight/4
    c = %Comps.Circle{center: {-xcc,ycc}, radius: 0.1, layer: "F.SilkS", width: 0.125}
    [p] ++ frontSilkBorder ++ backSilkBorder ++ [c]
  end


  def create_mod(params, pincount, rowcount, filename) do
    silktextheight  = params[:silktextheight]
    courtyardmargin = params[:courtyardmargin]
    pinpitch        = params[:pinpitch]
    rowpitch        = params[:rowpitch]
    padwidth        = params[:padwidth]
    padheight       = params[:padheight]

    bodylen     = pinpitch * (pincount - 1) + padwidth
    bodywid     = rowpitch * (rowcount - 1) + padheight
    bodyrad     = pinpitch / :math.cos(22.5 * :math.pi / 180.0) / 2.0
    crtydlength = bodylen / 2 + bodyrad / 2 + courtyardmargin
    crtydwidth  = bodywid / 2 + bodyrad / 2 + courtyardmargin / 2

    fcrtyd = make_box(crtydlength, crtydwidth, "F.CrtYd", 0.1)
    bcrtyd = make_box(crtydlength, crtydwidth, "B.CrtYd", 0.1)

    pins = for row <- 0..rowcount-1, do:
             for pin <- 1..pincount, do: make_pad(params, pin, row, pincount, rowcount)

    features = List.flatten(pins) ++ fcrtyd ++ bcrtyd

    {:ok, file} = File.open filename, [:write]
    refloc      = {0, -crtydwidth - 0.75 * silktextheight, 0}
    valloc      = {0, +crtydwidth + 0.75 * silktextheight, 0}
    m = %Comps.Module{name: "Header-1x1",
                           reflocation: refloc,
                           valuelocation: valloc,
                           textsize: {1,1}, textwidth: 0.15,
                           descr: "0.10in (2.54 mm) spacing unshrouded header",
                           tags: ["PTH", "unshrouded", "header"], isSMD: false,
                           features: features}
    IO.binwrite file, "#{m}"
    File.close file
  end


  def build(output_base_directory, library_name) do
    output_directory      = "#{output_base_directory}/#{library_name}.pretty"

    File.mkdir(output_directory)

    # Read in default values
    defaults = Footprints.Xml.read_defaults(%{}, "global_defaults.xml")


    # Append specific parameters for this 0.1" library (set of modules)
    drilldia = 0.9
    padsize = 1.75 * drilldia
    params = Map.merge defaults, %{pinpitch: 2.54, rowpitch: 2.54,
                                   padheight: padsize, padwidth: padsize,
                                   drilldia: drilldia}

    pinpitch = params[:pinpitch]
    devices = for pincount <- 1..40, rowcount <- 1..2, pincount>=rowcount, do: {pincount,rowcount}
    Enum.map(devices, fn {pincount,rowcount} ->
                  filename = "#{output_directory}/HDR#{round(pinpitch*100.0)}P#{pincount}x#{rowcount}.kicad_mod"
                  create_mod(params, pincount, rowcount, filename)
                end)



    # Append specific parameters for this 0.05" library (set of modules)
    drilldia = 0.57
    padsize = 1.75 * drilldia
    params = Map.merge defaults, %{pinpitch: 1.27, rowpitch: 1.27,
                                   padheight: padsize, padwidth: padsize,
                                   drilldia: drilldia}

    pinpitch = params[:pinpitch]
    devices = for pincount <- 1..40, rowcount <- 1..3, pincount>=rowcount, do: {pincount,rowcount}
    Enum.map(devices, fn {pincount,rowcount} ->
                  filename = "#{output_directory}/HDR#{round(pinpitch*100.0)}P#{pincount}x#{rowcount}.kicad_mod"
                  #IO.puts "Writing #{filename}"
                  create_mod(params, pincount, rowcount, filename)
                end)

    :ok
  end

end
