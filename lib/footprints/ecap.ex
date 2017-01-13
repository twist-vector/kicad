defmodule Footprints.ECap do
  alias Footprints.Components, as: Comps

  def create_mod(params, name, descr, tags, filename) do
    #
    # Device oriented left-to-right:  Body length is then in the KiCad x
    # direction, body width is in the y direction.
    #
    silktextheight    = params[:silktextheight]
    silktextwidth     = params[:silktextwidth]
    silkoutlinewidth  = params[:silkoutlinewidth]
    courtoutlinewidth = params[:courtoutlinewidth]
    courtyardmargin   = params[:courtyardmargin]
    placetickmargin   = params[:placetickmargin]
    toefillet         = params[:toefillet]
    heelfillet        = params[:heelfillet]
    sidefillet        = params[:sidefillet]
    pinlentol         = params[:pinlentol] # pin length is in the x direction
    pinwidthmin       = params[:pinwidthmin]
    pinwidthmax       = params[:pinwidthmax]
    pinsep            = params[:pinsep]
    placetol          = params[:placetol]
    fabtol            = params[:fabtol]
    bodylen           = params[:bodylen]
    bodywid           = params[:bodywid]
    cyldiam           = params[:cyldiam]
    legland           = params[:legland]
    pastemargin       = params[:solderpastemarginratio]
    fiduciallen       = params[:fiduciallen]
    fiducialradius    = params[:fiducialradius]
    maskmargin        = params[:soldermaskmargin]

    totaltol  = :math.sqrt(:math.pow(pinlentol, 2)+:math.pow(fabtol, 2)+:math.pow(placetol, 2))

    padSizeX = legland + heelfillet + toefillet + totaltol
    padSizeY = (pinwidthmax+pinwidthmin)/2 + 2*sidefillet + totaltol

    padCenterX = pinsep/2 + padSizeX/2 - heelfillet
    padCenterY = 0;

    crtydSizeX = 2*(max(padCenterX+padSizeX/2, bodylen/2) + courtyardmargin)
    crtydSizeY = 2*(max(padCenterY+padSizeY/2, bodywid/2) + courtyardmargin)

    pads = [Comps.padSMD(name: "1", shape: "rect", at: {-padCenterX, padCenterY}, size: {padSizeX, padSizeY}, pastemargin: pastemargin, maskmargin: maskmargin),
            Comps.padSMD(name: "2", shape: "rect", at: { padCenterX, padCenterY}, size: {padSizeX, padSizeY}, pastemargin: pastemargin, maskmargin: maskmargin)]


    x1 =   bodylen/2
    x2 = - bodylen/2 + bodylen/5
    x3 = - bodylen/2
    y1 =   bodywid/2
    y2 = y1 - bodywid/5
    xn = x1/2
    yn = :math.sqrt( (cyldiam/2)*(cyldiam/2) - xn*xn )

    yt = padSizeY/2 + placetickmargin
    xt = :math.sqrt( (cyldiam/2)*(cyldiam/2) - yt*yt )
    theta = :math.asin(yt/cyldiam)
    ang = 180 - 4*(theta*180/:math.pi)

    silk = [Comps.line(start: {x1, y1}, end: {x2, y1}, layer: "F.SilkS", width: silkoutlinewidth),
            Comps.line(start: {x2, y1}, end: {x3, y2}, layer: "F.SilkS", width: silkoutlinewidth),
            Comps.line(start: {x3, y2}, end: {x3, yt}, layer: "F.SilkS", width: silkoutlinewidth),
            Comps.line(start: {x3,-yt}, end: {x3,-y2}, layer: "F.SilkS", width: silkoutlinewidth),
            Comps.line(start: {x3,-y2}, end: {x2,-y1}, layer: "F.SilkS", width: silkoutlinewidth),
            Comps.line(start: {x2,-y1}, end: {x1,-y1}, layer: "F.SilkS", width: silkoutlinewidth),
            Comps.line(start: {x1,-y1}, end: {x1,-yt}, layer: "F.SilkS", width: silkoutlinewidth),
            Comps.line(start: {x1, yt}, end: {x1, y1}, layer: "F.SilkS", width: silkoutlinewidth),
            Comps.circle(center: {0,0}, radius: cyldiam/2, layer: "Eco1.User", width: silkoutlinewidth),
            Comps.arc(start: {0,0}, end: {xt,yt}, angle: ang, layer: "F.SilkS", width: silkoutlinewidth),
            Comps.arc(start: {0,0}, end: {xt,-yt}, angle: -ang, layer: "F.SilkS", width: silkoutlinewidth)]


    courtyard = Comps.box(ll: {-crtydSizeX/2,crtydSizeY/2},
                          ur: {crtydSizeX/2,-crtydSizeY/2},
                          layer: "F.CrtYd", width: courtoutlinewidth)

    outline = [Comps.line(start: {x1, y1}, end: {x2, y1}, layer: "Eco1.User", width: silkoutlinewidth),
               Comps.line(start: {x2, y1}, end: {x3, y2}, layer: "Eco1.User", width: silkoutlinewidth),
               Comps.line(start: {x3, y2}, end: {x3, -y2}, layer: "Eco1.User", width: silkoutlinewidth),
               Comps.line(start: {x3,-y2}, end: {x2,-y1}, layer: "Eco1.User", width: silkoutlinewidth),
               Comps.line(start: {x2,-y1}, end: {x1,-y1}, layer: "Eco1.User", width: silkoutlinewidth),
               Comps.line(start: {x1,-y1}, end: {x1,y1}, layer: "Eco1.User", width: silkoutlinewidth),
               Comps.line(start: {xn,-yn}, end: {xn,yn}, layer: "Eco1.User", width: silkoutlinewidth),
               Comps.circle(center: {0,0}, radius: cyldiam/2, layer: "Eco1.User", width: silkoutlinewidth)]


    # Center of mass fiducial
    com = [Comps.circle(center: {0,0}, radius: fiducialradius, layer: "Eco1.User", width: silkoutlinewidth),
           Comps.line(start: {-fiduciallen,0}, end: {fiduciallen,0}, layer: "Eco1.User", width: silkoutlinewidth),
           Comps.line(start: {0,-fiduciallen}, end: {0,fiduciallen}, layer: "Eco1.User", width: silkoutlinewidth)]

    features = pads ++ [Enum.join(courtyard, "\n  ")] ++
        [Enum.join(outline, "\n  ")] ++ silk ++ com

    refloc      = {-crtydSizeX/2 - 0.75*silktextheight, 0, 90}
    valloc      = { crtydSizeX/2 + 0.75*silktextheight, 0, 90}
    m = Comps.module(name: name,
                     valuelocation: valloc,
                     referencelocation: refloc,
                     textsize: {silktextheight,silktextwidth},
                     textwidth: silkoutlinewidth,
                     descr: descr,
                     tags: tags,
                     isSMD: false,
                     features: features)
    {:ok, file} = File.open filename, [:write]
    IO.binwrite file, "#{m}"
    File.close file
  end


  def build(library_name, device_file_name, basedefaults, overrides, output_base_directory, config_base_directory) do
    output_directory = "#{output_base_directory}/#{library_name}.pretty"
    File.mkdir(output_directory)

    # Override default parameters for this library (set of modules) and add
    # device specific values.  The override based on command line parameters
    # (passed in via `overrides` variable)
    temp = YamlElixir.read_from_file("#{config_base_directory}/#{device_file_name}")
    defaults = FootprintSupport.make_params("#{config_base_directory}/#{device_file_name}", basedefaults, overrides)

    for dev_name <- Dict.keys(temp) do
      if dev_name != "defaults" do

        # temp[dev_name] is a list of Dicts.  Each element is the parameters list
        # to be used for the device
        Enum.map(temp[dev_name], fn d ->
          p = Enum.map(d, fn {k,v} -> Map.put(%{}, String.to_atom(k), v) end)
              |> Enum.reduce(fn(data, acc)-> Map.merge(data,acc) end)
          params = Map.merge(defaults, p)
                   |> Map.merge(overrides)

          bl = params[:bodylen]*10
          bw = params[:bodywid]*10

          metriccode = List.flatten(:io_lib.format("~w~w", [round(bl),round(bw)]))
          imperialcode = if params[:inchcode] == nil do
                            bli = bl * 0.393701
                            bwi = bw * 0.393701
                            List.flatten(:io_lib.format("~w~w", [round(bli),round(bwi)]))
                         else
                            params[:inchcode]
                         end

          filename = "#{output_directory}/#{dev_name}-#{metriccode}-#{imperialcode}.kicad_mod"
          tags = ["SMD", "chip", metriccode]
          create_mod(params, "#{metriccode}_chip_dev",
                     "#{metriccode} (metric) chip device",
                     tags, filename)
        end)
      end
    end

    :ok
  end

end
