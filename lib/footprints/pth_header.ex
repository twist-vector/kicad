defmodule Footprints.PTHHeader do
  alias Footprints.Components, as: Comps



  def make_pin_outline(pinpitch, i, layer, {xc,yc}) do
    numpoints  = 8
    angle      = 180/numpoints * :math.pi/180.0

    bodyrad    = pinpitch / :math.cos(angle)/2.0;
    thetaStart = i*2.0*:math.pi/numpoints + angle
    thetaEnd   = (i+1)*2.0*:math.pi/numpoints + angle
    dxStart    = bodyrad * :math.cos(thetaStart)
    dyStart    = bodyrad * :math.sin(thetaStart)
    dxEnd      = bodyrad * :math.cos(thetaEnd)
    dyEnd      = bodyrad * :math.sin(thetaEnd)
    Comps.line(start: {xc+dxStart,yc+dyStart},
               end: {xc+dxEnd,yc+dyEnd},
               layer: layer, width: 0.1)
  end


  def make_outline(params, pincount, rowcount) do
    pinpitch        = params[:pinpitch]
    rowpitch        = params[:rowpitch]

    row = 1
    bottom = for pin <- 1..pincount do
      xc = -((pincount-1)/2*pinpitch) + (pin-1)*pinpitch
      yc = rowpitch*(rowcount-1)/2.0 - (row-1)*rowpitch
      edges = if rowcount == 1  and pincount == 1 do
                0..7
              else
                case pin do
                   1 -> [0,1,2,3,4]
           ^pincount -> [0,1,2,6,7]
                   _ -> [0,1,2]
                end
              end
       for n <- edges, do: make_pin_outline(pinpitch, n,"F.SilkS",{xc,yc})
    end

    row = rowcount
    top = for pin <- 1..pincount do
      xc = -((pincount-1)/2*pinpitch) + (pin-1)*pinpitch
      yc = rowpitch*(rowcount-1)/2.0 - (row-1)*rowpitch
      edges = case pin do
                   1 -> [2,3,4,5,6]
           ^pincount -> [0,4,5,6,7]
                   _ -> [4,5,6]
              end
       for n <- edges, do: make_pin_outline(pinpitch, n,"F.SilkS",{xc,yc})
    end

    rest = if rowcount > 1 do
      for row <- 2..rowcount-1 do
         for pin <- 1..pincount do
            xc = -((pincount-1)/2*pinpitch) + (pin-1)*pinpitch
            yc = rowpitch*(rowcount-1)/2.0 - (row-1)*rowpitch
            edges = case pin do
                         1 -> [2,3,4]
                 ^pincount -> [0,6,7]
                         _ -> []
                    end
             for n <- edges, do: make_pin_outline(pinpitch, n,"F.SilkS",{xc,yc})
          end
        end
    else
      []
    end

    List.flatten(bottom) ++ List.flatten(top) ++ List.flatten(rest)
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
    yc = rowpitch*(rowcount-1)/2.0 - (row-1)*rowpitch
    pn = (pin-1)*rowcount + row

    p = Comps.padPTH(name: "#{pn}", shape: "oval", at: {xc,yc},
                     size: {padwidth,padheight}, drill: drilldia)

    xcc = totallen/2 + padwidth/4
    ycc = totalwid/2 + padheight/4
    c = Comps.circle(center: {-xcc,ycc}, radius: 0.1, layer: "F.SilkS", width: 0.125)
    [p] ++ [c]
  end


  def create_mod(params, pincount, rowcount, filename) do
      silktextheight  = params[:silktextheight]
      courtyardmargin = params[:courtyardmargin]
      pinpitch        = params[:pinpitch]
      rowpitch        = params[:rowpitch]
      padwidth        = params[:padwidth]
      padheight       = params[:padheight]

      bodylen     = pinpitch*(pincount-1) + padwidth  # extent in x
      bodywid     = rowpitch*(rowcount-1) + padheight # extent in y

      crtydlength = (bodylen + padheight) + courtyardmargin
      crtydwidth  = (bodywid + padwidth) + courtyardmargin
      courtyard = Comps.box(ll: {-crtydlength/2,  crtydwidth/2},
                            ur: { crtydlength/2, -crtydwidth/2},
                            layer: "F.CrtYd", width: 0.1)

      pins = for row <- 1..rowcount, do:
               for pin <- 1..pincount, do: make_pad(params, pin, row, pincount, rowcount)

      frontSilkBorder = make_outline(params, pincount, rowcount)

      features = List.flatten(pins) ++ courtyard ++ frontSilkBorder

      {:ok, file} = File.open filename, [:write]
      refloc      = {-crtydlength/2 - 0.75*silktextheight, 0, 90}
      valloc      = { crtydlength/2 + 0.75*silktextheight, 0, 90}
      m = Comps.module(name: "Header_#{pincount}x#{rowcount}",
                       valuelocation: valloc,
                       referencelocation: refloc,
                       textsize: {1,1},
                       textwidth: 0.15,
                       descr: "#{pincount}x#{rowcount} 0.10in (2.54 mm) spacing unshrouded header",
                       tags: ["PTH", "unshrouded", "header"],
                       isSMD: false,
                       features: features)
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
