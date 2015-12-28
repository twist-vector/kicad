defmodule Footprints.Passives do
  alias Footprints.Components, as: Comps

  @library_name "SMD_Passives"
  @device_file_name "rcl_devices.yml"

  def create_mod(params, name, descr, tags, filename) do
    #
    # Device oriented left-to-right:  Body length is then in the KiCad x
    # direction, body width is in the y direction.
    #
    silktextheight    = params[:silktextheight]
    silktextwidth     = params[:silktextwidth]
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
    polarized         = params[:polarized]
    pastemargin       = params[:solderpastemarginratio]

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

    pads = [Comps.padSMD(name: "1", shape: "rect", at: {-padCenterX, padCenterY}, size: {padSizeX, padSizeY}, pastemargin: pastemargin),
            Comps.padSMD(name: "2", shape: "rect", at: { padCenterX, padCenterY}, size: {padSizeX, padSizeY}, pastemargin: pastemargin)]

    if polarized do
      silk = [Comps.line(start: {-padCenterX-padSizeX/2, -padSizeY/2-2*silkoutlinewidth},
                           end: { minInsideLengthX/2, -padSizeY/2-2*silkoutlinewidth},
                         layer: "F.SilkS",
                         width: silkoutlinewidth)] ++
             [Comps.line(start: {-padCenterX-padSizeX/2, padSizeY/2+2*silkoutlinewidth},
                           end: { minInsideLengthX/2, padSizeY/2+2*silkoutlinewidth},
                         layer: "F.SilkS",
                         width: silkoutlinewidth)] ++
              [Comps.circle(center: {-padCenterX-padSizeX/2-0.25,0}, radius: 0.05,
                            layer: "F.SilkS", width: silkoutlinewidth)]
    else
      silk = [Comps.line(start: {-minInsideLengthX/2, -padSizeY/2-2*silkoutlinewidth},
                           end: { minInsideLengthX/2, -padSizeY/2-2*silkoutlinewidth},
                         layer: "F.SilkS",
                         width: silkoutlinewidth)] ++
             [Comps.line(start: {-minInsideLengthX/2, padSizeY/2+2*silkoutlinewidth},
                           end: { minInsideLengthX/2, padSizeY/2+2*silkoutlinewidth},
                         layer: "F.SilkS",
                         width: silkoutlinewidth)]
    end
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


    features = pads ++ [Enum.join(courtyard, "\n  ")] ++
        [Enum.join(outline, "\n  ")] ++ silk

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


  def build(basedefaults, overrides, output_base_directory, config_base_directory) do
    output_directory = "#{output_base_directory}/#{@library_name}.pretty"
    File.mkdir(output_directory)

    # Override default parameters for this library (set of modules) and add
    # device specific values.  The override based on command line parameters
    # (passed in via `overrides` variable)
    temp = YamlElixir.read_from_file("#{config_base_directory}/#{@device_file_name}")
    p = Enum.map(temp["defaults"], fn({k,v})-> Map.put(%{}, String.to_atom(k), v) end)
        |> Enum.reduce(fn(data, acc)-> Map.merge(data,acc) end)
    p2 = Map.merge basedefaults, p
    defaults = Map.merge p2, overrides

    for dev_name <- Dict.keys(temp) do
      if dev_name != "defaults" do

        # temp[dev_name] is a list of Dicts.  Each element is the parameters list
        # to be used for the device
        Enum.map(temp[dev_name], fn d ->
          p = Enum.map(d, fn {k,v} -> Map.put(%{}, String.to_atom(k), v) end)
              |> Enum.reduce(fn(data, acc)-> Map.merge(data,acc) end)
          params = Map.merge defaults, p

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
          create_mod(params, "#{metriccode}_chip_dev",
                     "#{metriccode} (metric) chip device",
                     tags, filename)
        end)
      end
    end

    :ok
  end

end
