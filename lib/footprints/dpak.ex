defmodule Footprints.DPak do
  alias Footprints.Components, as: Comps

  @library_name "DPAK"
  @device_file_name "TO_devices.yml"

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
    pinlentol         = params[:pinlentol]
    placetol          = params[:placetol]
    fabtol            = params[:fabtol]
    courtyardmargin   = params[:courtyardmargin]
    pincount          = params[:pincount]
    pinpitch          = params[:pinpitch]

    totalwidmin = params[:totalwidmin]
    totalwidmax = params[:totalwidmax]
    bodyspanminx = params[:bodyspanminx]
    bodyspanmaxx = params[:bodyspanmaxx]
    bodyspanminy = params[:bodyspanminy]
    bodyspanmaxy = params[:bodyspanmaxy]
    pinwidthmin = params[:pinwidthmin]
    pinwidthmax = params[:pinwidthmax]
    leglandmin = params[:leglandmin]
    leglandmax = params[:leglandmax]
    epadohangmin = params[:epadohangmin]
    epadohangmax = params[:epadohangmax]
    epadspanx = params[:epadspanx]
    epadspany = params[:epadspany]

    totaltol = 0#:math.sqrt(:math.pow(pinlentol, 2)+:math.pow(fabtol, 2)+:math.pow(placetol, 2))

    bodywid = (bodyspanminy+bodyspanmaxy)/2
    bodylen = (bodyspanminx+bodyspanmaxx)/2
    totalwid = (totalwidmin+totalwidmax)/2
    legland  = (leglandmin+leglandmax)/2
    pinwidth = (pinwidthmin+pinwidthmax)/2
    epadohang = (epadohangmin+epadohangmax)/2

    pinwidthtol = (pinwidthmax-pinwidthmin)/2
    pinlentol = (totalwidmax-totalwidmin)/2
    bodywidtol = (bodyspanmaxy-bodyspanminy)/2

    maxOutsideWidth = totalwid + 2*(legland+pinlentol)

    wmin = pinwidth - pinwidthtol;

    stride = round(pincount/2)
    span = (pincount/2-1)*pinpitch
    padSizeY = legland + heelfillet + toefillet + totaltol
    padSizeX = (pinwidth - pinwidthtol) + 2*sidefillet + totaltol

    y = totalwid-bodywid/2 - legland/2 + toefillet/2 - heelfillet/2
    pads = for pin <- 1..pincount do
      ###x = -pinpitch*(pincount)/2 + 2*(pin-1)*pinpitch
      x = -pinpitch + (pin-1) * (2*pinpitch)/(pincount-1)
      Comps.padSMD(name: "#{pin}", shape: "rect", at: {x, y}, size: {padSizeX, padSizeY})
    end

    epad = [Comps.padSMD(name: "#{pincount+1}", shape: "rect",
                           at: {0,-epadohang},
                         size: {epadspanx+2*sidefillet, epadspany+2*sidefillet})]

    pins = for pin <- 1..pincount do
      x = -pinpitch + (pin-1) * (2*pinpitch)/(pincount-1)
      [Footprints.Components.box(ll: {x-pinwidth/2, totalwid-bodywid/2},
                                 ur: {x+pinwidth/2, bodywid/2},
                                 layer: "Dwgs.User", width: courtoutlinewidth),
       Footprints.Components.box(ll: {x-pinwidth/2, totalwid-bodywid/2-legland},
                                  ur: {x+pinwidth/2, bodywid/2},
                                  layer: "Dwgs.User", width: courtoutlinewidth)]
    end



    crtydSizeX = bodylen + 2*courtyardmargin
    courtyard = Footprints.Components.box(ll: {-crtydSizeX/2, totalwid-bodywid/2 + toefillet + courtyardmargin},
                                          ur: { crtydSizeX/2, -bodywid/2 - courtyardmargin - epadohang/2},
                                          layer: "F.CrtYd", width: courtoutlinewidth)


    outline = [Footprints.Components.box(ll: {-bodylen/2, bodywid/2}, ur: { bodylen/2,-bodywid/2}, layer: "F.SilkS", width: silkoutlinewidth)]

    # Pin 1 marker (circle)
    xcc = -pinpitch*(pincount)/2 - padSizeX/2 - 4*silkoutlinewidth
    ycc = totalwid-bodywid/2
    c = Comps.circle(center: {xcc,ycc}, radius: silkoutlinewidth, layer: "F.SilkS", width: silkoutlinewidth)

   # Center of mass fiducial
   com = [Footprints.Components.circle(center: {0,0}, radius: 0.5,
                                       layer: "Eco1.User", width: silkoutlinewidth),
          Footprints.Components.line(start: {-0.75,0}, end: {0.75,0},
                                     layer: "Eco1.User", width: silkoutlinewidth),
          Footprints.Components.line(start: {0,-0.75}, end: {0,0.75},
                                     layer: "Eco1.User", width: silkoutlinewidth)]


    features = List.flatten(pads) ++ epad ++ courtyard ++ [c] ++
               List.flatten(pins) ++ List.flatten(outline)++ com

    refloc = if params[:refsinside], do:
                 {0, bodywid/4-silktextheight/2, 0},   #{0, 0.8*silktextheight, 0},
             else:
                 {-crtydSizeX/2 - 0.75*silktextheight, 0, 90}
    valloc = if params[:refsinside], do:
                 {0, -bodywid/4+silktextheight/2, 0},   #{0, -0.8*silktextheight, 0},
             else:
                 { crtydSizeX/2 + 0.75*silktextheight, 0, 90}

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
          tags = ["SMD", "#{String.upcase(dev_name)}"]
          name = "#{devcode}"
          descr = "#{params[:pincount]+1} pin #{params[:pinpitch]}in pitch #{params[:bodylen]}x#{params[:totalwid]} #{String.upcase(dev_name)} device"
          create_mod(params, name, descr, tags, filename)
        end)
      end
    end

    :ok
  end

end
