defmodule Footprints.SOT do
  alias Footprints.Components, as: Comps

  def create_mod(params, name, descr, tags, filename) do
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
    pinwidthtol       = params[:pinwidthtol]
    placetol          = params[:placetol]
    fabtol            = params[:fabtol]
    courtyardmargin   = params[:courtyardmargin]
    bodylen           = params[:bodylen]
    bodywid           = params[:bodywid]
    legland           = params[:legland]
    pinwidth          = params[:pinwidth]
    pincount          = params[:pincount]
    pinpitch          = params[:pinpitch]
    totalwid          = params[:totalwid]
    pastemargin       = params[:solderpastemarginratio]
    maskmargin        = params[:soldermaskmargin]
    shape             = params[:padshape]


    totaltol = :math.sqrt(:math.pow(pinlentol, 2)+:math.pow(fabtol, 2)+:math.pow(placetol, 2))

    maxOutsideWidth = totalwid + 2*pinlentol

    padSizeY = legland + heelfillet + toefillet + totaltol
    padSizeX = (pinwidth - pinwidthtol) + 2*sidefillet + totaltol

    y = (totalwid-legland)/2.0 + toefillet/2 - + heelfillet/2
    pads = case pincount do
             3 -> [Comps.pad(:smd, "1", shape, {-pinpitch,y}, {padSizeX,padSizeY}, pastemargin, maskmargin),
                   Comps.pad(:smd, "2", shape, { pinpitch,y}, {padSizeX,padSizeY}, pastemargin, maskmargin),
                   Comps.pad(:smd, "3", shape, { 0,-y}, {padSizeX,padSizeY}, pastemargin, maskmargin)]

             4 -> [Comps.pad(:smd, "1", shape, {-pinpitch, y}, {padSizeX,padSizeY}, pastemargin, maskmargin),
                   Comps.pad(:smd, "2", shape, { pinpitch, y}, {padSizeX,padSizeY}, pastemargin, maskmargin),
                   Comps.pad(:smd, "3", shape, {-pinpitch,-y}, {padSizeX,padSizeY}, pastemargin, maskmargin),
                   Comps.pad(:smd, "4", shape, { pinpitch,-y}, {padSizeX,padSizeY}, pastemargin, maskmargin)]

             5 -> [Comps.pad(:smd, "1", shape, {-pinpitch, y}, {padSizeX,padSizeY}, pastemargin, maskmargin),
                   Comps.pad(:smd, "2", shape, { 0, y}, {padSizeX,padSizeY}, pastemargin, maskmargin),
                   Comps.pad(:smd, "3", shape, { pinpitch, y}, {padSizeX,padSizeY}, pastemargin, maskmargin),
                   Comps.pad(:smd, "4", shape, { pinpitch,-y}, {padSizeX,padSizeY}, pastemargin, maskmargin),
                   Comps.pad(:smd, "5", shape, {-pinpitch,-y}, {padSizeX,padSizeY}, pastemargin, maskmargin)]

             6 -> [Comps.pad(:smd, "1", shape, {-pinpitch, y}, {padSizeX,padSizeY}, pastemargin, maskmargin),
                   Comps.pad(:smd, "2", shape, { 0, y}, {padSizeX,padSizeY}, pastemargin, maskmargin),
                   Comps.pad(:smd, "3", shape, { pinpitch, y}, {padSizeX,padSizeY}, pastemargin, maskmargin),
                   Comps.pad(:smd, "4", shape, { pinpitch,-y}, {padSizeX,padSizeY}, pastemargin, maskmargin),
                   Comps.pad(:smd, "5", shape, {0,-y}, {padSizeX,padSizeY}, pastemargin, maskmargin),
                   Comps.pad(:smd, "6", shape, {-pinpitch,-y}, {padSizeX,padSizeY}, pastemargin, maskmargin)]

             8 -> [Comps.pad(:smd, "1", shape, {-1.5*pinpitch, y}, {padSizeX,padSizeY}, pastemargin, maskmargin),
                   Comps.pad(:smd, "2", shape, {-0.5*pinpitch, y}, {padSizeX,padSizeY}, pastemargin, maskmargin),
                   Comps.pad(:smd, "3", shape, { 0.5*pinpitch, y}, {padSizeX,padSizeY}, pastemargin, maskmargin),
                   Comps.pad(:smd, "4", shape, { 1.5*pinpitch, y}, {padSizeX,padSizeY}, pastemargin, maskmargin),
                   Comps.pad(:smd, "5", shape, { 1.5*pinpitch,-y}, {padSizeX,padSizeY}, pastemargin, maskmargin),
                   Comps.pad(:smd, "6", shape, { 0.5*pinpitch,-y}, {padSizeX,padSizeY}, pastemargin, maskmargin),
                   Comps.pad(:smd, "7", shape, {-0.5*pinpitch,-y}, {padSizeX,padSizeY}, pastemargin, maskmargin),
                   Comps.pad(:smd, "8", shape, {-1.5*pinpitch,-y}, {padSizeX,padSizeY}, pastemargin, maskmargin)]

             _ -> []
           end


    pins = case pincount do
             3 -> [Comps.box({-(pinpitch+pinwidth/2), totalwid/2}, {-(pinpitch-pinwidth/2),bodywid/2}, "Dwgs.User", docoutlinewidth),
                   Comps.box({ (pinpitch+pinwidth/2), totalwid/2}, { (pinpitch-pinwidth/2),bodywid/2}, "Dwgs.User", docoutlinewidth),
                   Comps.box({ -pinwidth/2, -bodywid/2}, { pinwidth/2, -totalwid/2}, "Dwgs.User", docoutlinewidth)]

             4 -> [Comps.box({-(pinpitch+pinwidth/2), totalwid/2}, {-(pinpitch-pinwidth/2),bodywid/2}, "Dwgs.User", docoutlinewidth),
                   Comps.box({ (pinpitch+pinwidth/2), totalwid/2}, { (pinpitch-pinwidth/2),bodywid/2}, "Dwgs.User", docoutlinewidth),
                   Comps.box({-(pinpitch+pinwidth/2), -bodywid/2}, {-(pinpitch-pinwidth/2), -totalwid/2}, "Dwgs.User", docoutlinewidth),
                   Comps.box({ (pinpitch-pinwidth/2), -bodywid/2}, { (pinpitch+pinwidth/2), -totalwid/2}, "Dwgs.User", docoutlinewidth)]

             5 -> [Comps.box({-(pinpitch+pinwidth/2), totalwid/2}, {-(pinpitch-pinwidth/2),bodywid/2}, "Dwgs.User", docoutlinewidth),
                   Comps.box({ -pinwidth/2, totalwid/2}, { pinwidth/2,bodywid/2}, "Dwgs.User", docoutlinewidth),
                   Comps.box({ pinpitch-pinwidth/2, totalwid/2}, { pinpitch+pinwidth/2, bodywid/2}, "Dwgs.User", docoutlinewidth),
                   Comps.box({ (pinpitch-pinwidth/2), -bodywid/2}, { (pinpitch+pinwidth/2), -totalwid/2}, "Dwgs.User", docoutlinewidth),
                   Comps.box({-(pinpitch+pinwidth/2), -bodywid/2}, {-(pinpitch-pinwidth/2), -totalwid/2}, "Dwgs.User", docoutlinewidth)]

             6 -> [Comps.box({-(pinpitch+pinwidth/2), totalwid/2}, {-(pinpitch-pinwidth/2),bodywid/2}, "Dwgs.User", docoutlinewidth),
                   Comps.box({ -pinwidth/2, totalwid/2}, { pinwidth/2,bodywid/2}, "Dwgs.User", docoutlinewidth),
                   Comps.box({ pinpitch-pinwidth/2, totalwid/2}, { pinpitch+pinwidth/2, bodywid/2}, "Dwgs.User", docoutlinewidth),
                   Comps.box({ (pinpitch-pinwidth/2), -bodywid/2}, { (pinpitch+pinwidth/2), -totalwid/2}, "Dwgs.User", docoutlinewidth),
                   Comps.box({ -pinwidth/2, -bodywid/2}, { pinwidth/2,-totalwid/2}, "Dwgs.User", docoutlinewidth),
                   Comps.box({-(pinpitch+pinwidth/2), -bodywid/2}, {-(pinpitch-pinwidth/2), -totalwid/2}, "Dwgs.User", docoutlinewidth)]
             _ -> []
           end


     # Pin 1 marker (circle)
     xcc = -bodylen/2 - padSizeX/2  #-pincount/2*pinpitch - padSizeX/2 - silkoutlinewidth
     ycc = totalwid/2
     c = Comps.circle({xcc,ycc}, silkoutlinewidth, "F.SilkS", silkoutlinewidth)

    crtydSizeX = bodylen + 2*courtyardmargin
    crtydSizeY = maxOutsideWidth + 2*toefillet + 2*courtyardmargin
    courtyard = Footprints.Components.box({-crtydSizeX/2,crtydSizeY/2},
                                          {crtydSizeX/2,-crtydSizeY/2},
                                          "F.CrtYd", courtoutlinewidth)


    outline = [Footprints.Components.box({-bodylen/2,bodywid/2},
                                         {bodylen/2,-bodywid/2},
                                         "F.SilkS", silkoutlinewidth)]


    features = pads ++ courtyard ++ pins ++ outline ++ [c]

    refloc = {0,0}   #if params[:refsinside], do:
                     #   {0, bodywid/4-silktextheight/2},
                     #else:
                     #   {-crtydSizeX/2 - 0.75*silktextheight, 0}
    valloc =  {0,0}  #if params[:refsinside], do:
                     #   {0, -bodywid/4+silktextheight/2},
                     #else:
                     #   { crtydSizeX/2 + 0.75*silktextheight, 0}
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
          widcode = List.flatten(:io_lib.format("~w", [round(params[:totalwid]*100)]))
          lencode = List.flatten(:io_lib.format("~w", [round(params[:bodylen]*100)]))

          #  Example: SOT23-96P290x237-3
          devcode = "#{String.upcase(dev_name)}-#{pitchcode}P#{lencode}x#{widcode}-#{pincount}"
          filename = "#{output_directory}/#{devcode}.kicad_mod"
          tags = ["SMD", "#{String.upcase(dev_name)}"]
          name = "#{devcode}"
          descr = "#{params[:pincount]} pin #{params[:pinpitch]}in pitch #{params[:bodylen]}x#{params[:totalwid]} #{String.upcase(dev_name)} device"
          create_mod(params, name, descr, tags, filename)
        end)
      end
    end

    :ok
  end

end
