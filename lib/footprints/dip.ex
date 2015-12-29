defmodule Footprints.DIP do
  alias Footprints.Components, as: Comps

  @library_name "DIP"
  @device_file_name "DIP_devices.yml"


  def get_body_len(params) do
    pinpitch = params[:pinpitch]
    pincount = params[:pincount]

    (pinpitch * (pincount/2 - 1)) + 3.0
  end

  def create_mod(params, name, descr, tags, filename) do
    silktextheight    = params[:silktextheight]
    silktextwidth     = params[:silktextwidth]
    silkoutlinewidth  = params[:silkoutlinewidth]
    courtoutlinewidth = params[:courtoutlinewidth]
    docoutlinewidth   = params[:docoutlinewidth]
    courtyardmargin   = params[:courtyardmargin]
    bodywid           = params[:bodywid]
    pincount          = params[:pincount]
    pinpitch          = params[:pinpitch]
    totalwid          = params[:totalwid]
    pinonesidelineoffset = params[:pinonesidelineoffset]
    padwidth          = params[:padwidth]
    padheight         = params[:padheight]
    drilldia          = params[:drilldia]
    pinrad            = params[:pinrad]


    bodylen = get_body_len(params)
    stride = round(pincount/2)
    span = (pincount/2-1)*pinpitch

    pads = for pinpair <- 1..stride do
      y = totalwid/2.0
      x = -span/2.0 + (pinpair-1)*pinpitch
      [Comps.padPTH(name: "#{pinpair}", shape: "oval", at: {x,y}, size: {padwidth, padheight}, drill: drilldia),
       Comps.padPTH(name: "#{pincount-pinpair+1}", shape: "oval", at: {x,-y}, size: {padwidth, padheight}, drill: drilldia)]
    end


    # Bounding "courtyard" for the device
    crtydSizeX = bodylen + 2*courtyardmargin
    crtydSizeY = (totalwid + padheight) + 2*courtyardmargin
    courtyard = Comps.box(ll: {-crtydSizeX/2,  crtydSizeY/2},
                          ur: { crtydSizeX/2, -crtydSizeY/2},
                          layer: "F.CrtYd", width: silkoutlinewidth)


    outline = [Footprints.Components.box(ll: {-bodylen/2,bodywid/2},
                                         ur: {bodylen/2,-bodywid/2},
                                      layer: "F.SilkS", width: docoutlinewidth),
               Footprints.Components.line(start: {-bodylen/2,bodywid/2-pinonesidelineoffset},
                                            end: {bodylen/2,bodywid/2-pinonesidelineoffset},
                                          layer: "F.SilkS", width: silkoutlinewidth)]

    pins = for pinpair <- 1..stride do
      x = -span/2.0 + (pinpair-1)*pinpitch
      [Footprints.Components.box(ll: {x-pinrad/2, bodywid/2},
                                 ur: {x+pinrad/2, totalwid/2},
                                 layer: "Dwgs.User", width: courtoutlinewidth),
       Footprints.Components.box(ll: {x-pinrad/2, -bodywid/2},
                                 ur: {x+pinrad/2, -totalwid/2},
                                 layer: "Dwgs.User", width: courtoutlinewidth)]
    end

    # Pin 1 marker (circle)
    xcc = -span/2.0 - padwidth/2 - 3*silkoutlinewidth
    ycc = totalwid/2
    c = Comps.circle(center: {xcc,ycc}, radius: silkoutlinewidth, layer: "F.SilkS", width: silkoutlinewidth)


    # Center of mass fiducial
    com = [Footprints.Components.circle(center: {0,0}, radius: 0.5,
                                        layer: "Eco1.User", width: silkoutlinewidth),
           Footprints.Components.line(start: {-0.75,0}, end: {0.75,0},
                                      layer: "Eco1.User", width: silkoutlinewidth),
           Footprints.Components.line(start: {0,-0.75}, end: {0,0.75},
                                      layer: "Eco1.User", width: silkoutlinewidth)]

    # Put all the module pieces together, create, and write the module
    features = List.flatten(pads) ++ courtyard ++ [c] ++ outline ++ com ++ pins

    refloc = if params[:refsinside], do:
                 {0, bodywid/4-silktextheight/2, 0},   #{0, 0.8*silktextheight, 0},
             else:
                 {-crtydSizeX/2 - 0.75*silktextheight, 0, 90}
    valloc = if params[:refsinside], do:
                 {0, -bodywid/4+silktextheight/2, 0},   #{0, -0.8*silktextheight, 0},
             else:
                 { crtydSizeX/2 + 0.75*silktextheight, 0, 90}

    {:ok, file} = File.open filename, [:write]
    m = Comps.module(name: name,
                     valuelocation: valloc,
                     referencelocation: refloc,
                     textsize: {silktextheight,silktextwidth},
                     textwidth: silkoutlinewidth,
                     descr: descr,
                     tags: tags,
                     isSMD: false,
                     features: features)
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

          pincount = params[:pincount]
          pitchcode = List.flatten(:io_lib.format("~w", [round(params[:pinpitch]*100)]))
          widcode = List.flatten(:io_lib.format("~w", [round(params[:bodywid]*100)]))
          lencode = List.flatten(:io_lib.format("~w", [round(get_body_len(params)*100)]))

          #  Example: DIP254P490x600-8
          devcode = "#{String.upcase(dev_name)}#{pitchcode}P#{lencode}x#{widcode}-#{pincount}"
          filename = "#{output_directory}/#{devcode}.kicad_mod"
          tags = ["PTH", "#{String.upcase(dev_name)}"]
          name = "#{devcode}"
          descr = "#{params[:pincount]} pin #{params[:pinpitch]}in pitch #{params[:bodylen]}x#{params[:totalwid]} #{String.upcase(dev_name)} device"
          create_mod(params, name, descr, tags, filename)
        end)
      end
    end

    :ok
  end

end
