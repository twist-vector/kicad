defmodule Footprints.QFP do
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
    epadpastemargin   = params[:epadsolderpastemarginratio]
    maskmargin        = params[:soldermaskmargin]

    totaltol = :math.sqrt(:math.pow(pinlentol, 2)+:math.pow(fabtol, 2)+:math.pow(placetol, 2))

    maxOutsideLength = (totalwid+pinlentol)

    stride = round(pincount/4)
    span = (pincount/4-1)*pinpitch
    padSizeY = legland + heelfillet + toefillet + totaltol
    padSizeX = (pinwidth - pinwidthtol) + 2*sidefillet + totaltol

    pads = for pinpair <- 1..stride do
      x = -span/2.0 + (pinpair-1)*pinpitch
      y = (totalwid-legland)/2.0 + toefillet/2 - + heelfillet/2

      [Comps.pad(:smd, "#{pinpair}", "rect", {x,y}, {padSizeX,padSizeY}, pastemargin, maskmargin),
       Comps.pad(:smd, "#{3*stride-pinpair+1}", "rect", {x,-y}, {padSizeX,padSizeY}, pastemargin, maskmargin),
       Comps.pad(:smd, "#{4*stride-pinpair+1}", "rect", {-y,-x}, {padSizeY,padSizeX}, pastemargin, maskmargin),
       Comps.pad(:smd, "#{2*stride-pinpair+1}", "rect", {y,x}, {padSizeY,padSizeX}, pastemargin, maskmargin)]
    end

    epad = if params[:epadwid] != nil do
      [Comps.pad(:smd, "EP", "rect", {0,0}, {params[:epadlen], params[:epadwid]}, epadpastemargin, 0)]
    else
      []
    end

    pins = for pinpair <- 1..stride do
      x = -span/2.0 + (pinpair-1)*pinpitch
      topbot =
      [Footprints.Components.box(ll: {x-pinwidth/2,  bodywid/2}, ur: {x+pinwidth/2,  totalwid/2}, layer: "Dwgs.User", width: docoutlinewidth),
       Footprints.Components.box(ll: {x-pinwidth/2, -bodywid/2}, ur: {x+pinwidth/2, -totalwid/2}, layer: "Dwgs.User", width: docoutlinewidth)] ++
      [Footprints.Components.box(ll: {x-pinwidth/2,  bodywid/2}, ur: {x+pinwidth/2, (totalwid)/2-legland}, layer: "Dwgs.User", width: docoutlinewidth),
       Footprints.Components.box(ll: {x-pinwidth/2, -bodywid/2}, ur: {x+pinwidth/2, -(totalwid)/2+legland}, layer: "Dwgs.User", width: docoutlinewidth)]

      y = -span/2.0 + (pinpair-1)*pinpitch
      leftright =
      [Footprints.Components.box(ll: {-bodywid/2, y-pinwidth/2, }, ur: {-totalwid/2, y+pinwidth/2}, layer: "Dwgs.User", width: docoutlinewidth),
       Footprints.Components.box(ll: { bodywid/2, y-pinwidth/2, }, ur: { totalwid/2, y+pinwidth/2}, layer: "Dwgs.User", width: docoutlinewidth)] ++
      [Footprints.Components.box(ll: {-bodywid/2, y-pinwidth/2}, ur: {-(totalwid/2-legland), y+pinwidth/2}, layer: "Dwgs.User", width: docoutlinewidth),
       Footprints.Components.box(ll: { bodywid/2, y-pinwidth/2}, ur: { (totalwid/2-legland), y+pinwidth/2}, layer: "Dwgs.User", width: docoutlinewidth)]

      topbot ++ leftright
    end


    crtydSizeX = maxOutsideLength + 2*toefillet + 2*courtyardmargin
    crtydSizeY = crtydSizeX
    courtyard = Footprints.Components.box(ll: {-crtydSizeX/2, crtydSizeY/2},
                                          ur: { crtydSizeX/2,-crtydSizeY/2},
                                          layer: "F.CrtYd", width: courtoutlinewidth)


    outline = [Footprints.Components.box(ll: {-bodylen/2, bodywid/2}, ur: { bodylen/2,-bodywid/2}, layer: "F.SilkS", width: silkoutlinewidth),
               Footprints.Components.line(start: {-bodylen/2,bodywid/2-0.75}, end: {-bodylen/2+0.75,bodywid/2}, layer: "F.SilkS", width: silkoutlinewidth)]

    # Pin 1 marker (circle)
    xcc = -span/2 - padSizeX/2 - 3*silkoutlinewidth
    ycc = totalwid/2
    c = Comps.circle(center: {xcc,ycc}, radius: silkoutlinewidth, layer: "F.SilkS", width: silkoutlinewidth)

    features = List.flatten(pads) ++ epad ++ courtyard ++ [c] ++
               List.flatten(pins) ++ List.flatten(outline)

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
          widcode = List.flatten(:io_lib.format("~w", [round(params[:totalwid]*100)]))
          lencode = List.flatten(:io_lib.format("~w", [round(params[:bodylen]*100)]))
          padcode = if params[:epadwid] != nil do
            List.flatten(:io_lib.format("-T~wx~w", [round(params[:epadlen]*100),
                                                    round(params[:epadwid]*100)]))
          else
            ""
          end

          #  Example: SOIC127P490x600-8-T330x241
          devcode = "#{String.upcase(dev_name)}#{pitchcode}P#{lencode}x#{widcode}-#{pincount}#{padcode}"
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
