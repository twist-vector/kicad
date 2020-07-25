defmodule Footprints.Diodes do
  alias Footprints.Components, as: Comps


  def create_mod(params, name, descr, tags, filename) do
    #
    # Device oriented left-to-right:  Body length is then in the KiCad x
    # direction, body width is in the y direction.
    #
    silktextheight    = params[:silktextheight]
    silktextwidth     = params[:silktextwidth]
    silktextthickness = params[:silktextthickness]
    silkoutlinewidth  = params[:silkoutlinewidth]
    courtoutlinewidth = params[:courtoutlinewidth]
    docoutlinewidth   = params[:docoutlinewidth]
    toefillet         = params[:toefillet]
    heelfillet        = params[:heelfillet]
    sidefillet        = params[:sidefillet]
    pinlentol         = params[:pinlentol] # pin length is in the x direction
    placetol          = params[:placetol]
    lentol            = params[:lentol]
    fabtol            = params[:fabtol]
    widtol            = params[:widtol]
    courtyardmargin   = params[:courtyardmargin]
    bodylen           = params[:bodylen]
    bodywid           = params[:bodywid]
    legland           = params[:legland]
    pastemargin       = params[:solderpastemarginratio]
    maskmargin        = params[:soldermaskmargin]


    totaltol  = :math.sqrt(:math.pow(pinlentol, 2)+:math.pow(fabtol, 2)+:math.pow(placetol, 2))

    xmin = bodylen - lentol # Minimum possible body length
    xmax = bodylen + lentol # Maximum possible body length

    minInsideLengthX  = xmin - 2*(legland+pinlentol)
    maxOutsideLengthX = xmax
    maxExtentY = bodywid + widtol

    padSizeX = (maxOutsideLengthX - minInsideLengthX)/2 + heelfillet + toefillet + totaltol
    padSizeY = maxExtentY + 2*sidefillet + totaltol

    padCenterX = minInsideLengthX/2 + padSizeX/2 - heelfillet
    padCenterY = 0;

    crtydSizeX = 2*(max(padCenterX+padSizeX/2, bodylen/2) + courtyardmargin)
    crtydSizeY = 2*(max(padCenterY+padSizeY/2, bodywid/2) + courtyardmargin)

    pads = [Comps.pad(:smd, "1", "rect", {-padCenterX, padCenterY}, {padSizeX, padSizeY}, pastemargin, maskmargin),
            Comps.pad(:smd, "2", "rect", { padCenterX, padCenterY}, {padSizeX, padSizeY}, pastemargin, maskmargin)]

    silk = [Comps.line(start: {-padCenterX-padSizeX/2, -padSizeY/2-2*silkoutlinewidth},
                         end: { minInsideLengthX/2, -padSizeY/2-2*silkoutlinewidth},
                       layer: "F.SilkS",
                       width: silkoutlinewidth)] ++
           [Comps.line(start: {-padCenterX-padSizeX/2, padSizeY/2+2*silkoutlinewidth},
                         end: { minInsideLengthX/2, padSizeY/2+2*silkoutlinewidth},
                       layer: "F.SilkS",
                       width: silkoutlinewidth)] ++
            [Comps.circle(center: {-padCenterX-padSizeX/2-0.25,0}, radius: 0.05,
                          layer: "F.SilkS", width: silkoutlinewidth)] ++
            [Comps.line(start: {-minInsideLengthX/2+silkoutlinewidth,-padSizeY/2},
                          end: {-minInsideLengthX/2+silkoutlinewidth,padSizeY/2},
                        layer: "F.SilkS", width: silkoutlinewidth)]

    courtyard = Footprints.Components.box(ll: {-crtydSizeX/2,crtydSizeY/2},
                                          ur: {crtydSizeX/2,-crtydSizeY/2},
                                          layer: "F.CrtYd", width: courtoutlinewidth)

    outline = Footprints.Components.box(ll: {-bodylen/2,bodywid/2},
                                        ur: {bodylen/2,-bodywid/2},
                                        layer: "Dwgs.User", width: docoutlinewidth) ++
              Footprints.Components.box(ll: {-bodylen/2,bodywid/2},
                                        ur: {-bodylen/2+legland,-bodywid/2},
                                        layer: "Dwgs.User", width: docoutlinewidth) ++
              Footprints.Components.box(ll: {bodylen/2-legland,bodywid/2},
                                        ur: {bodylen/2,-bodywid/2},
                                        layer: "Dwgs.User", width: docoutlinewidth)


    features = pads ++ [Enum.join(courtyard, "\n  ")] ++ silk ++
                 [Enum.join(outline, "\n  ")]

    refloc   = {-crtydSizeX/2 - 0.75*silktextheight, 0}
    valloc   = { crtydSizeX/2 + 0.75*silktextheight, 0}
    textsize = {silktextheight,silktextwidth}

    m = Comps.module(name, descr, features, refloc, valloc, textsize, silktextthickness, tags)

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


    for dev_name <- Map.keys(temp) do
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
          metriccode = List.flatten(:io_lib.format("~2..0w~2..0w", [round(bl),round(bw)]))
          imperialcode = if params[:inchcode] == nil do
            bli = bl * 0.393701
            bwi = bw * 0.393701
             List.flatten(:io_lib.format("~2..0w~2..0w", [round(bli),round(bwi)]))
          else
             params[:inchcode]
          end

          filename = "#{output_directory}/#{dev_name}-#{metriccode}-#{imperialcode}.kicad_mod"
          tags = ["SMD", "chip", metriccode]
          create_mod(params, "#{metriccode}_chip_diode",
                     "#{metriccode} (metric) chip diode",
                     tags, filename)
        end)
      end
    end

    :ok
  end

end
