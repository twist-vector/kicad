defmodule Footprints.SOIC do
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
    docoutlinewidth   = params[:docoutlinewidth]
    toefillet         = params[:toefillet]
    heelfillet        = params[:heelfillet]
    sidefillet        = params[:sidefillet]
    pinlentol         = params[:pinlentol] # pin length is in the x direction
    pinwidthtol       = params[:pinwidthtol]
    placetol          = params[:placetol]
    lentol            = params[:lentol]
    fabtol            = params[:fabtol]
    widtol            = params[:widtol]
    courtyardmargin   = params[:courtyardmargin]
    bodylen           = params[:bodylen]
    bodywid           = params[:bodywid]
    legland           = params[:legland]
    pinwidth          = params[:pinwidth]
    pincount          = params[:pincount]
    pinpitch          = params[:pinpitch]
    totalwid          = params[:totalwid]
    pinonesidelineoffset = params[:pinonesidelineoffset]

    totaltol = :math.sqrt(:math.pow(pinlentol, 2)+:math.pow(fabtol, 2)+:math.pow(placetol, 2))

    xmin = bodylen - lentol # Minimum possible body length
    xmax = bodylen + lentol # Maximum possible body length
    ymin = totalwid - lentol
    ymax = totalwid + lentol
    wmin = pinwidth - pinwidthtol; # Minimum possible pin width
    tmin = legland-pinlentol
    sxmax = xmax - 2*(legland-pinlentol)
    gxmin = sxmax - 2*heelfillet - totaltol
    zxmax = xmin + 2*toefillet + totaltol
    zymax = ymin + 2*toefillet + totaltol

    minInsideLengthX  = xmin - 2*(legland+pinlentol)
    maxOutsideLengthX = xmax
    maxExtentY = bodywid + widtol

    stride = round(pincount/2)
    span = (pincount/2-1)*pinpitch
    padSizeY = (zxmax-gxmin)/2.0
    padSizeX = wmin + 2*sidefillet + totaltol

    pads = for pinpair <- 1..stride do
      y = totalwid/2.0
      x = -span/2.0 + (pinpair-1)*pinpitch
      pinlength = (totalwid-bodywid)/2
      [Comps.padSMD(name: "#{pinpair}", shape: "rect", at: {x, y}, size: {padSizeX, padSizeY}),
       Comps.padSMD(name: "#{pincount-pinpair+1}", shape: "rect", at: {x, -y}, size: {padSizeX, padSizeY})]
    end

    epad = if params[:epadwid] != nil do
      [Comps.padSMD(name: "EP", shape: "rect", at: {0,0},
              size: {params[:epadlen], params[:epadwid]})]
    else
      []
    end

    pins = for pinpair <- 1..stride do
      y = totalwid/2.0
      x = -span/2.0 + (pinpair-1)*pinpitch
      pinlength = (totalwid-bodywid)/2
      [Footprints.Components.box(ll: {x-pinwidth/2, bodywid/2},
                                 ur: {x+pinwidth/2, totalwid/2},
                                 layer: "Dwgs.User", width: courtoutlinewidth),
       Footprints.Components.box(ll: {x-pinwidth/2, -bodywid/2},
                                 ur: {x+pinwidth/2, -totalwid/2},
                                 layer: "Dwgs.User", width: courtoutlinewidth)]
    end


    crtydSizeX = max(xmax+padSizeX/2, zxmax+padSizeX/2) + 2*courtyardmargin
    crtydSizeY = max(ymax+padSizeY/2, zymax+padSizeY/2) + 2*courtyardmargin
    courtyard = Footprints.Components.box(ll: {-crtydSizeX/2,crtydSizeY/2},
                                          ur: {crtydSizeX/2,-crtydSizeY/2},
                                          layer: "F.CrtYd", width: courtoutlinewidth)


    outline = [Footprints.Components.box(ll: {-bodylen/2,bodywid/2},
                                        ur: {bodylen/2,-bodywid/2},
                                        layer: "F.SilkS", width: docoutlinewidth),
               Footprints.Components.line(start: {-bodylen/2,bodywid/2-pinonesidelineoffset},
                                            end: {bodylen/2,bodywid/2-pinonesidelineoffset},
                                          layer: "F.SilkS", width: silkoutlinewidth)]

    # Pin 1 marker (circle)
    xcc = -span/2 - padSizeX/2 - 3*silkoutlinewidth
    ycc = totalwid/2
    c = Comps.circle(center: {xcc,ycc}, radius: silkoutlinewidth,
                     layer: "F.SilkS", width: silkoutlinewidth)

    features = List.flatten(pads) ++ epad ++ courtyard ++ [c] ++
               List.flatten(pins) ++ List.flatten(outline)

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


  def build(basedefaults, output_base_directory, config_base_directory) do
    library_name = "SOP"
    output_directory = "#{output_base_directory}/#{library_name}.pretty"
    File.mkdir(output_directory)

    # Override default parameters for this library (set of modules) and add
    # device specific values.
    temp = YamlElixir.read_from_file("#{config_base_directory}/SOP_devices.yml")
    d = Enum.map(temp["defaults"], fn({k,v})-> Map.put(%{}, String.to_atom(k), v) end)
               |> Enum.reduce(fn(data, acc)-> Map.merge(data,acc) end)
    defaults =  Map.merge basedefaults, d

    for dev_name <- Dict.keys(temp) do
      if dev_name != "defaults" do

        # temp[dev_name] is a list of Dicts.  Each element is the parameters list
        # to be used for the device
        Enum.map(temp[dev_name], fn d ->
          p = Enum.map(d, fn {k,v} -> Map.put(%{}, String.to_atom(k), v) end)
              |> Enum.reduce(fn(data, acc)-> Map.merge(data,acc) end)
          params = Map.merge defaults, p

          pincount = params[:pincount]
          pitchcode = List.flatten(:io_lib.format("~w", [round(params[:pinpitch]*100)]))
          widcode = List.flatten(:io_lib.format("~w", [round(params[:totalwid]*100)]))
          lencode = List.flatten(:io_lib.format("~w", [round(params[:bodylen]*100)]))
          padcode = if params[:epadwid] != nil do
            List.flatten(:io_lib.format("-T~wx~w", [round(params[:epadlen]*100),
                                                    round(params[:epadwid]*100)]))
          else
            ""
          end

          #  Example: SOIC127P490x600-8-T330x241
          filename = "#{output_directory}/#{String.upcase(dev_name)}#{pitchcode}P#{lencode}x#{widcode}-#{pincount}#{padcode}.kicad_mod"
          IO.puts filename
          tags = ["SMD", "SOIC"]
          create_mod(params, "name", "descr", tags, filename)
        end)
      end
    end

    :ok
  end

end
