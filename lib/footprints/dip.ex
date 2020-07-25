defmodule Footprints.DIP do
  alias Footprints.Components, as: Comps


  def get_body_len(params) do
    pinpitch = params[:pinpitch]
    pincount = params[:pincount]

    (pinpitch * (pincount/2 - 1)) + 3.0
  end

  def create_mod(params, name, descr, tags, filename) do
    silktextheight    = params[:silktextheight]
    silktextwidth     = params[:silktextwidth]
    silktextthickness = params[:silktextthickness]
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
    maskmargin        = params[:soldermaskmargin]


    bodylen = get_body_len(params)
    stride = round(pincount/2)
    span = (pincount/2-1)*pinpitch

    pads = for pinpair <- 1..stride do
      y = totalwid/2.0
      x = -span/2.0 + (pinpair-1)*pinpitch
      [Comps.pad(:pth, "#{pinpair}", "oval", {x, y}, {padwidth, padheight}, drilldia, maskmargin),
       Comps.pad(:pth, "#{pinpair-pinpair+1}", "oval", {x,-y}, {padwidth, padheight}, drilldia, maskmargin)]
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

    # Put all the module pieces together, create, and write the module
    features = List.flatten(pads) ++ courtyard ++ [c] ++ outline ++ pins

    refloc = if params[:refsinside], do:
                 {0, bodywid/4-silktextheight/2},
             else:
                 {-crtydSizeX/2 - 0.75*silktextheight, 0}
    valloc = if params[:refsinside], do:
                 {0, -bodywid/4+silktextheight/2},
             else:
                 { crtydSizeX/2 + 0.75*silktextheight, 0}
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
