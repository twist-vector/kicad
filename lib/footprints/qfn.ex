defmodule Footprints.QFN do
  alias Footprints.Components, as: Comps

  @library_name "QFN"
  @device_file_name "QFN_devices.yml"

  def create_mod(params, name, descr, tags, filename) do
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
    fabtol            = params[:fabtol]
    courtyardmargin   = params[:courtyardmargin]
    bodylen           = params[:bodylen]
    bodywid           = params[:bodywid]
    legland           = params[:legland]
    pinwidth          = params[:pinwidth]
    pincount          = params[:pincount]
    pinpitch          = params[:pinpitch]
    placetickmargin   = params[:placetickmargin]
    pastemargin       = params[:solderpastemarginratio]
    epadpastemargin   = params[:epadsolderpastemarginratio]

    totaltol = :math.sqrt(:math.pow(pinlentol, 2)+:math.pow(fabtol, 2)+:math.pow(placetol, 2))

    maxOutsideLength = (bodywid+pinlentol)

    stride = round(pincount/4)
    span = (pincount/4-1)*pinpitch
    padSizeY = legland + heelfillet + toefillet + totaltol
    padSizeX = (pinwidth - pinwidthtol) + 2*sidefillet + totaltol

    pads = for pinpair <- 1..stride do
      x = -span/2.0 + (pinpair-1)*pinpitch
      y = (bodywid-legland)/2.0 + toefillet/2 - + heelfillet/2

      [Comps.padSMD(name: "#{pinpair}",            shape: "rect", at: { x,  y}, size: {padSizeX, padSizeY}, pastemargin: pastemargin),
       Comps.padSMD(name: "#{3*stride-pinpair+1}", shape: "rect", at: { x, -y}, size: {padSizeX, padSizeY}, pastemargin: pastemargin),
       Comps.padSMD(name: "#{4*stride-pinpair+1}", shape: "rect", at: {-y, -x}, size: {padSizeY, padSizeX}, pastemargin: pastemargin),
       Comps.padSMD(name: "#{2*stride-pinpair+1}", shape: "rect", at: { y,  x}, size: {padSizeY, padSizeX}, pastemargin: pastemargin)]
    end

    epad = if params[:epadwid] != nil do
      [Comps.padSMD(name: "EP", shape: "rect", at: {0,0},
              size: {params[:epadlen], params[:epadwid]},
              pastemargin: epadpastemargin)]
    else
      []
    end

    pins = for pinpair <- 1..stride do
      x = -span/2.0 + (pinpair-1)*pinpitch
      topbot =
      [Footprints.Components.box(ll: {x-pinwidth/2,  bodywid/2}, ur: {x+pinwidth/2,  bodywid/2}, layer: "Dwgs.User", width: docoutlinewidth),
       Footprints.Components.box(ll: {x-pinwidth/2, -bodywid/2}, ur: {x+pinwidth/2, -bodywid/2}, layer: "Dwgs.User", width: docoutlinewidth)] ++
      [Footprints.Components.box(ll: {x-pinwidth/2,  bodywid/2}, ur: {x+pinwidth/2, (bodywid)/2-legland}, layer: "Dwgs.User", width: docoutlinewidth),
       Footprints.Components.box(ll: {x-pinwidth/2, -bodywid/2}, ur: {x+pinwidth/2, -(bodywid)/2+legland}, layer: "Dwgs.User", width: docoutlinewidth)]

      y = -span/2.0 + (pinpair-1)*pinpitch
      leftright =
      [Footprints.Components.box(ll: {-bodywid/2, y-pinwidth/2, }, ur: {-bodywid/2, y+pinwidth/2}, layer: "Dwgs.User", width: docoutlinewidth),
       Footprints.Components.box(ll: { bodywid/2, y-pinwidth/2, }, ur: { bodywid/2, y+pinwidth/2}, layer: "Dwgs.User", width: docoutlinewidth)] ++
      [Footprints.Components.box(ll: {-bodywid/2, y-pinwidth/2}, ur: {-(bodywid/2-legland), y+pinwidth/2}, layer: "Dwgs.User", width: docoutlinewidth),
       Footprints.Components.box(ll: { bodywid/2, y-pinwidth/2}, ur: { (bodywid/2-legland), y+pinwidth/2}, layer: "Dwgs.User", width: docoutlinewidth)]

      topbot ++ leftright
    end


    crtydSizeX = maxOutsideLength + 2*toefillet + 2*courtyardmargin
    crtydSizeY = crtydSizeX
    courtyard = Footprints.Components.box(ll: {-crtydSizeX/2, crtydSizeY/2},
                                          ur: { crtydSizeX/2,-crtydSizeY/2},
                                          layer: "F.CrtYd", width: courtoutlinewidth)


    x = (pincount/4-1)*pinpitch/2 + padSizeX/2 + silkoutlinewidth + placetickmargin
    y = (pincount/4-1)*pinpitch/2 + padSizeX/2 + silkoutlinewidth + placetickmargin
    outline = [Footprints.Components.line(start: {-bodylen/2, bodywid/2}, end: {-x, bodywid/2}, layer: "F.SilkS", width: silkoutlinewidth),
               Footprints.Components.line(start: {-bodylen/2, bodywid/2}, end: {-bodylen/2, y}, layer: "F.SilkS", width: silkoutlinewidth),
               Footprints.Components.line(start: { bodylen/2, bodywid/2}, end: { x, bodywid/2}, layer: "F.SilkS", width: silkoutlinewidth),
               Footprints.Components.line(start: { bodylen/2, bodywid/2}, end: { bodylen/2, y}, layer: "F.SilkS", width: silkoutlinewidth),
               Footprints.Components.line(start: {-bodylen/2,-bodywid/2}, end: {-x,-bodywid/2}, layer: "F.SilkS", width: silkoutlinewidth),
               Footprints.Components.line(start: {-bodylen/2,-bodywid/2}, end: {-bodylen/2,-y}, layer: "F.SilkS", width: silkoutlinewidth),
               Footprints.Components.line(start: { bodylen/2,-bodywid/2}, end: { x,-bodywid/2}, layer: "F.SilkS", width: silkoutlinewidth),
               Footprints.Components.line(start: { bodylen/2,-bodywid/2}, end: { bodylen/2,-y}, layer: "F.SilkS", width: silkoutlinewidth),

               Footprints.Components.line(start: {-bodylen/2, y}, end: {-x, bodywid/2}, layer: "F.SilkS", width: silkoutlinewidth)
              ]

    # Pin 1 marker (circle)
    xcc = -span/2 - padSizeX/2 - 3*silkoutlinewidth
    ycc = bodywid/2 + 3*silkoutlinewidth
    c = Comps.circle(center: {xcc,ycc}, radius: silkoutlinewidth, layer: "F.SilkS", width: silkoutlinewidth)

   # Center of mass fiducial
   com = [Footprints.Components.circle(center: {0,0}, radius: 0.5, layer: "Eco1.User", width: silkoutlinewidth),
          Footprints.Components.line(start: {-0.75,0}, end: {0.75,0}, layer: "Eco1.User", width: silkoutlinewidth),
          Footprints.Components.line(start: {0,-0.75}, end: {0,0.75}, layer: "Eco1.User", width: silkoutlinewidth)]


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
          pitchcode = List.flatten(:io_lib.format("~w", [round(params[:pinpitch]*100)]))
          widcode = List.flatten(:io_lib.format("~w", [round(params[:bodywid]*100)]))
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
          descr = "#{params[:pincount]} pin #{params[:pinpitch]}in pitch #{params[:bodylen]}x#{params[:bodywid]} #{String.upcase(dev_name)} device"
          create_mod(params, name, descr, tags, filename)
        end)
      end
    end

    :ok
  end

end
