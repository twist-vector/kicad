defmodule Footprints.DPak do
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
    toefillet         = params[:toefillet]
    heelfillet        = params[:heelfillet]
    sidefillet        = params[:sidefillet]
    courtyardmargin   = params[:courtyardmargin]
    pincount          = params[:pincount]
    pinpitch          = params[:pinpitch]
    pastemargin       = params[:solderpastemarginratio]
    totalwidmin       = params[:totalwidmin]
    totalwidmax       = params[:totalwidmax]
    bodyspanminx      = params[:bodyspanminx]
    bodyspanmaxx      = params[:bodyspanmaxx]
    bodyspanminy      = params[:bodyspanminy]
    bodyspanmaxy      = params[:bodyspanmaxy]
    pinwidthmin       = params[:pinwidthmin]
    pinwidthmax       = params[:pinwidthmax]
    leglandmin        = params[:leglandmin]
    leglandmax        = params[:leglandmax]
    epadohangmin      = params[:epadohangmin]
    epadohangmax      = params[:epadohangmax]
    epadspanx         = params[:epadspanx]
    epadspany         = params[:epadspany]
    maskmargin        = params[:soldermaskmargin]
    shape             = params[:padshape]


    totaltol = 0#:math.sqrt(:math.pow(pinlentol, 2)+:math.pow(fabtol, 2)+:math.pow(placetol, 2))

    bodywid = (bodyspanminy+bodyspanmaxy)/2
    bodylen = (bodyspanminx+bodyspanmaxx)/2
    totalwid = (totalwidmin+totalwidmax)/2
    legland  = (leglandmin+leglandmax)/2
    pinwidth = (pinwidthmin+pinwidthmax)/2
    epadohang = (epadohangmin+epadohangmax)/2

    pinwidthtol = (pinwidthmax-pinwidthmin)/2

    padSizeY = legland + heelfillet + toefillet + totaltol
    padSizeX = (pinwidth - pinwidthtol) + 2*sidefillet + totaltol

    y = totalwid-bodywid/2 - legland/2 + toefillet/2 - heelfillet/2
    pads = for pin <- 1..pincount do
      ###x = -pinpitch*(pincount)/2 + 2*(pin-1)*pinpitch
      x = -pinpitch + (pin-1) * (2*pinpitch)/(pincount-1)
      Comps.pad(:smd, "#{pin}", shape, {x,y}, {padSizeX, padSizeY}, pastemargin, maskmargin)
    end

    epad = [Comps.pad(:smd, "#{pincount+1}", shape, {0,-epadohang}, {epadspanx+2*sidefillet, epadspany+2*sidefillet}, pastemargin, maskmargin)]

    pins = for pin <- 1..pincount do
      x = -pinpitch + (pin-1) * (2*pinpitch)/(pincount-1)
      [Footprints.Components.box({x-pinwidth/2, totalwid-bodywid/2},
                                 {x+pinwidth/2, bodywid/2},
                                 "Dwgs.User", courtoutlinewidth),
       Footprints.Components.box({x-pinwidth/2, totalwid-bodywid/2-legland},
                                 {x+pinwidth/2, bodywid/2},
                                 "Dwgs.User", courtoutlinewidth)]
    end



    crtydSizeX = bodylen + 2*courtyardmargin
    courtyard = Footprints.Components.box({-crtydSizeX/2, totalwid-bodywid/2 + toefillet + courtyardmargin},
                                          { crtydSizeX/2, -bodywid/2 - courtyardmargin - epadohang/2},
                                          "F.CrtYd", courtoutlinewidth)


    outline = [Footprints.Components.box({-bodylen/2, bodywid/2}, { bodylen/2,-bodywid/2}, "F.SilkS", silkoutlinewidth)]

    # Pin 1 marker (circle)
    xcc = -pinpitch*(pincount)/2 - padSizeX/2 - 4*silkoutlinewidth
    ycc = totalwid-bodywid/2
    c = Comps.circle({xcc,ycc}, silkoutlinewidth, "F.SilkS", silkoutlinewidth)


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
          totalwid = (params[:totalwidmin]+params[:totalwidmax])/2
          bodylen = (params[:bodyspanminx]+params[:bodyspanmaxx])/2
          pitchcode = List.flatten(:io_lib.format("~w", [round(params[:pinpitch]*100)]))
          widcode = List.flatten(:io_lib.format("~w", [round(totalwid*100)]))
          lencode = List.flatten(:io_lib.format("~w", [round(bodylen*100)]))
          padcode = if params[:epadspany] != nil do
            List.flatten(:io_lib.format("-T~wx~w", [round(params[:epadspanx]*100),
                                                    round(params[:epadspany]*100)]))
          else
            ""
          end

          #  Example: TO-263-457P660x910-2-T540
          devcode = "#{String.upcase(dev_name)}-#{pitchcode}P#{lencode}x#{widcode}-#{pincount}#{padcode}"
          filename = "#{output_directory}/#{devcode}.kicad_mod"
          tags = ["SMD", "#{String.upcase(dev_name)}"] ++ params[:altnames]
          name = "#{devcode}"
          descr = "#{params[:pincount]+1} pin #{params[:pinpitch]}in pitch #{params[:bodylen]}x#{params[:totalwid]} #{String.upcase(dev_name)} device"
          create_mod(params, name, descr, tags, filename)
        end)
      end
    end

    :ok
  end

end
