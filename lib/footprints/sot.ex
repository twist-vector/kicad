defmodule Footprints.SOT do
  alias Footprints.Components, as: Comps

  @library_name "SOT"
  @device_file_name "SOT_devices.yml"


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
    totalwid          = params[:totalwid]

    totaltol = :math.sqrt(:math.pow(pinlentol, 2)+:math.pow(fabtol, 2)+:math.pow(placetol, 2))

    maxOutsideWidth = totalwid + 2*pinlentol

    padSizeY = legland + heelfillet + toefillet + totaltol
    padSizeX = (pinwidth - pinwidthtol) + 2*sidefillet + totaltol

    y = (totalwid-legland)/2.0 + toefillet/2 - + heelfillet/2
    pads = case pincount do
             3 -> [Comps.padSMD(name: "1", shape: "rect", at: {-pinpitch, y}, size: {padSizeX, padSizeY}),
                   Comps.padSMD(name: "2", shape: "rect", at: { pinpitch, y}, size: {padSizeX, padSizeY}),
                   Comps.padSMD(name: "3", shape: "rect", at: { 0, -y}, size: {padSizeX, padSizeY})]

             4 -> [Comps.padSMD(name: "1", shape: "rect", at: {-pinpitch, y}, size: {padSizeX, padSizeY}),
                   Comps.padSMD(name: "2", shape: "rect", at: { pinpitch, y}, size: {padSizeX, padSizeY}),
                   Comps.padSMD(name: "3", shape: "rect", at: {-pinpitch, -y}, size: {padSizeX, padSizeY}),
                   Comps.padSMD(name: "4", shape: "rect", at: { pinpitch, -y}, size: {padSizeX, padSizeY})]

             5 -> [Comps.padSMD(name: "1", shape: "rect", at: {-pinpitch, y}, size: {padSizeX, padSizeY}),
                   Comps.padSMD(name: "2", shape: "rect", at: { 0, y}, size: {padSizeX, padSizeY}),
                   Comps.padSMD(name: "3", shape: "rect", at: { pinpitch, y}, size: {padSizeX, padSizeY}),
                   Comps.padSMD(name: "4", shape: "rect", at: { pinpitch, -y}, size: {padSizeX, padSizeY}),
                   Comps.padSMD(name: "5", shape: "rect", at: {-pinpitch, -y}, size: {padSizeX, padSizeY})]

             6 -> [Comps.padSMD(name: "1", shape: "rect", at: {-pinpitch, y}, size: {padSizeX, padSizeY}),
                   Comps.padSMD(name: "2", shape: "rect", at: { 0, y}, size: {padSizeX, padSizeY}),
                   Comps.padSMD(name: "3", shape: "rect", at: { pinpitch, y}, size: {padSizeX, padSizeY}),
                   Comps.padSMD(name: "4", shape: "rect", at: { pinpitch, -y}, size: {padSizeX, padSizeY}),
                   Comps.padSMD(name: "5", shape: "rect", at: {0, -y}, size: {padSizeX, padSizeY}),
                   Comps.padSMD(name: "6", shape: "rect", at: {-pinpitch, -y}, size: {padSizeX, padSizeY})]
             _ -> []
           end


    pins = case pincount do
             3 -> [Comps.box(ll: {-(pinpitch+pinwidth/2), totalwid/2},         ur: {-(pinpitch-pinwidth/2),bodywid/2}, layer: "Dwgs.User", width: docoutlinewidth),
                   Comps.box(ll: { (pinpitch+pinwidth/2), totalwid/2},         ur: { (pinpitch-pinwidth/2),bodywid/2}, layer: "Dwgs.User", width: docoutlinewidth),
                   Comps.box(ll: { -pinwidth/2, -bodywid/2}, ur: { pinwidth/2, -totalwid/2}, layer: "Dwgs.User", width: docoutlinewidth)]

             4 -> [Comps.box(ll: {-(pinpitch+pinwidth/2), totalwid/2},         ur: {-(pinpitch-pinwidth/2),bodywid/2}, layer: "Dwgs.User", width: docoutlinewidth),
                   Comps.box(ll: { (pinpitch+pinwidth/2), totalwid/2},         ur: { (pinpitch-pinwidth/2),bodywid/2}, layer: "Dwgs.User", width: docoutlinewidth),
                   Comps.box(ll: {-(pinpitch+pinwidth/2), -bodywid/2}, ur: {-(pinpitch-pinwidth/2), -totalwid/2}, layer: "Dwgs.User", width: docoutlinewidth),
                   Comps.box(ll: { (pinpitch-pinwidth/2), -bodywid/2}, ur: { (pinpitch+pinwidth/2), -totalwid/2}, layer: "Dwgs.User", width: docoutlinewidth)]

             5 -> [Comps.box(ll: {-(pinpitch+pinwidth/2), totalwid/2},         ur: {-(pinpitch-pinwidth/2),bodywid/2}, layer: "Dwgs.User", width: docoutlinewidth),
                   Comps.box(ll: { -pinwidth/2, totalwid/2},         ur: { pinwidth/2,bodywid/2}, layer: "Dwgs.User", width: docoutlinewidth),
                   Comps.box(ll: { pinpitch-pinwidth/2, totalwid/2}, ur: { pinpitch+pinwidth/2, bodywid/2}, layer: "Dwgs.User", width: docoutlinewidth),
                   Comps.box(ll: { (pinpitch-pinwidth/2), -bodywid/2}, ur: { (pinpitch+pinwidth/2), -totalwid/2}, layer: "Dwgs.User", width: docoutlinewidth),
                   Comps.box(ll: {-(pinpitch+pinwidth/2), -bodywid/2}, ur: {-(pinpitch-pinwidth/2), -totalwid/2}, layer: "Dwgs.User", width: docoutlinewidth)]

             6 -> [Comps.box(ll: {-(pinpitch+pinwidth/2), totalwid/2},         ur: {-(pinpitch-pinwidth/2),bodywid/2}, layer: "Dwgs.User", width: docoutlinewidth),
                   Comps.box(ll: { -pinwidth/2, totalwid/2},         ur: { pinwidth/2,bodywid/2}, layer: "Dwgs.User", width: docoutlinewidth),
                   Comps.box(ll: { pinpitch-pinwidth/2, totalwid/2}, ur: { pinpitch+pinwidth/2, bodywid/2}, layer: "Dwgs.User", width: docoutlinewidth),
                   Comps.box(ll: { (pinpitch-pinwidth/2), -bodywid/2}, ur: { (pinpitch+pinwidth/2), -totalwid/2}, layer: "Dwgs.User", width: docoutlinewidth),
                   Comps.box(ll: { -pinwidth/2, -bodywid/2},         ur: { pinwidth/2,-totalwid/2}, layer: "Dwgs.User", width: docoutlinewidth),
                   Comps.box(ll: {-(pinpitch+pinwidth/2), -bodywid/2}, ur: {-(pinpitch-pinwidth/2), -totalwid/2}, layer: "Dwgs.User", width: docoutlinewidth)]
             _ -> []
           end


     # Pin 1 marker (circle)
     xcc = -pinpitch - padSizeX/2 - 3*silkoutlinewidth
     ycc = totalwid/2
     c = Comps.circle(center: {xcc,ycc}, radius: silkoutlinewidth, layer: "F.SilkS", width: silkoutlinewidth)

    crtydSizeX = bodylen + 2*courtyardmargin
    crtydSizeY = maxOutsideWidth + 2*toefillet + 2*courtyardmargin
    courtyard = Footprints.Components.box(ll: {-crtydSizeX/2,crtydSizeY/2},
                                          ur: {crtydSizeX/2,-crtydSizeY/2},
                                          layer: "F.CrtYd", width: courtoutlinewidth)


    outline = [Footprints.Components.box(ll: {-bodylen/2,bodywid/2},
                                        ur: {bodylen/2,-bodywid/2},
                                        layer: "F.SilkS", width: silkoutlinewidth)]


   # Center of mass fiducial
   com = [Footprints.Components.circle(center: {0,0}, radius: 0.3,
                                       layer: "Eco1.User", width: silkoutlinewidth),
          Footprints.Components.line(start: {-0.5,0}, end: {0.5,0},
                                     layer: "Eco1.User", width: silkoutlinewidth),
          Footprints.Components.line(start: {0,-0.5}, end: {0,0.5},
                                     layer: "Eco1.User", width: silkoutlinewidth)]


    features = pads ++ courtyard ++ pins ++ outline ++ [c] ++ com

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
