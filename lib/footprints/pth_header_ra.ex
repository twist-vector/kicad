defmodule Footprints.PTHHeaderRA do
  alias Footprints.Components, as: Comps


  def make_box(ll={llx,lly}, ur={urx,ury}, layer, thick) do
    [%Comps.Line{start:         ll, end: {urx, lly}, layer: layer, width: thick},
     %Comps.Line{start: {urx, lly}, end:         ur, layer: layer, width: thick},
     %Comps.Line{start:         ur, end: {llx, ury}, layer: layer, width: thick},
     %Comps.Line{start: {llx, ury}, end:         ll, layer: layer, width: thick}]
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

    p = %Comps.PadPTH{name: "#{pn}", shape: "oval", at: {xc,yc},
           size: {padwidth,padheight}, drill: drilldia}

    xcc = totallen/2 + padwidth/4
    ycc = totalwid/2 + padheight/4
    c = %Comps.Circle{center: {-xcc,ycc}, radius: 0.1, layer: "F.SilkS", width: 0.125}
    [p] ++ [c]
  end


  def create_mod(params, pincount, rowcount, filename) do
    silktextheight  = params[:silktextheight]
    courtyardmargin = params[:courtyardmargin]
    pinpitch        = params[:pinpitch]
    padwidth        = params[:padwidth]
    padheight       = params[:padheight]
    pindia          = params[:pindia]

    bodylen     = pinpitch * (pincount - 1) + padwidth
    crtydlength = bodylen / 2 + padwidth / 2 + courtyardmargin


    ll = {-crtydlength,
           pinpitch*(rowcount-1)/2 + padheight + courtyardmargin}
    ur = { crtydlength,
          -pinpitch*(rowcount-1)/2 - 1.52 - 2.54 - 5.84 - courtyardmargin/2}
    fcrtyd = make_box(ll, ur, "F.CrtYd",  0.1)

    ll = {-pinpitch*(pincount-1)/2-pinpitch/2,
          -pinpitch*(rowcount-1)/2 - 1.52}
    ur = { pinpitch*(pincount-1)/2+pinpitch/2,
          -pinpitch*(rowcount-1)/2 - 1.52 - 2.54}
    frontSilkBorder = make_box(ll, ur, "F.SilkS",  0.125)


    frontSilkPin = for pin <- 1..pincount do
          ll = {-pinpitch*(pincount-1)/2 + (pin-1)*pinpitch - pindia/2,
                -pinpitch*(rowcount-1)/2 - 1.52 - 2.54}
          ur = {-pinpitch*(pincount-1)/2 + (pin-1)*pinpitch + pindia/2,
                -pinpitch*(rowcount-1)/2 - 1.52 - 2.54 - 5.84}
           make_box(ll, ur, "F.SilkS",  0.125)
      end


    pins = for row <- 0..rowcount-1, do:
             for pin <- 1..pincount, do: make_pad(params, pin, row, pincount, rowcount)

    features = List.flatten(pins) ++ frontSilkBorder ++
               List.flatten(frontSilkPin)  ++ fcrtyd

    {:ok, file} = File.open filename, [:write]
    refloc      = {-crtydlength - 0.75 * silktextheight, 0, 90}
    valloc      = { crtydlength + 0.75 * silktextheight, 0, 90}
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
                                   pindia: 0.64, drilldia: drilldia}

    pinpitch = params[:pinpitch]
    devices = for pincount <- 1..40, rowcount <- 1..3, pincount>=rowcount, do: {pincount,rowcount}
    Enum.map(devices, fn {pincount,rowcount} ->
                  filename = "#{output_directory}/HDR_RA#{round(pinpitch*100.0)}P#{pincount}x#{rowcount}.kicad_mod"
                  #IO.puts "Writing #{filename}"
                  create_mod(params, pincount, rowcount, filename)
                end)

    :ok
  end

end
