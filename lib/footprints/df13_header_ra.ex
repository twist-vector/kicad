defmodule Footprints.DF13HeaderRA do
  alias Footprints.Components, as: Comps

  @library_name "PTH_Headers"
  @device_file_name "DF13Header_devices.yml"


  def create_mod(params, pincount, rowcount, filename) do
      silktextheight    = params[:silktextheight]
      silktextwidth     = params[:silktextwidth]
      silktextthickness = params[:silktextthickness]
      silkoutlinewidth  = params[:silkoutlinewidth]
      courtyardmargin   = params[:courtyardmargin]
      pinpitch          = params[:pinpitch]
      padwidth          = params[:padwidth]
      padheight         = params[:padheight]
      bodywid           = params[:bodywid]

      # All pins aligned at y=0
      #  lower face at y=0.90
      #  upper face at y=-4.50
      lower = 0.90
      upper = -4.50

      rowpitch = pinpitch

      bodylen  = pinpitch*(pincount-1) + 2.9
      totallen = bodylen;
      totalwid = bodywid;

      # Bounding "courtyard" for the device
      crtydlength = (bodylen + padheight) + courtyardmargin
      courtyard = Comps.box(ll: {-crtydlength/2, lower+courtyardmargin},
                            ur: { crtydlength/2, upper-courtyardmargin},
                            layer: "F.CrtYd", width: silkoutlinewidth)

      # The grid of pads.  We'll call the common function from the PTHHeader
      # module for each pin location.
      pads = for pin <- 1..pincount, do:
                if pin == 1, do:
                  Footprints.PTHHeader.make_pad(params, pin, 1, pincount, 1, "rect"),
                else:
                  Footprints.PTHHeader.make_pad(params, pin, 1, pincount, 1)


      # Outline
      y1 = -0.85
      outline = [Comps.line(start: {-bodylen/2,lower}, end: {bodylen/2,lower}, layer: "F.SilkS", width: silkoutlinewidth),
                 Comps.line(start: {-bodylen/2,upper}, end: {bodylen/2,upper}, layer: "F.SilkS", width: silkoutlinewidth),
                 Comps.line(start: {-bodylen/2,upper}, end: {-bodylen/2,lower}, layer: "F.SilkS", width: silkoutlinewidth),
                 Comps.line(start: {bodylen/2,upper}, end: {bodylen/2,lower}, layer: "F.SilkS", width: silkoutlinewidth),
                 Comps.line(start: {-bodylen/2,y1}, end: {bodylen/2,y1}, layer: "F.SilkS", width: silkoutlinewidth)]


      # Put all the module pieces together, create, and write the module
      features = List.flatten(pads) ++ courtyard ++ outline

      refloc      = if pincount > 3, do:
                         {0, (lower+upper)/2, 0},
                    else:
                         {-crtydlength/2 - 0.75*silktextheight, (lower+upper)/2, 90}
      valloc      = if pincount > 3, do:
                         {0, (lower+upper)/2-1.5*silktextheight, 0},
                    else:
                         { crtydlength/2 + 0.75*silktextheight, (lower+upper)/2, 90}


      descr = "Hirose DF13 right angle through hole connector";
      tags = ["PTH", "header", "shrouded"]
      name = "DF13-#{pincount}P-1.25DS"
      {:ok, file} = File.open filename, [:write]
      m = Comps.module(name: name,
                       valuelocation: valloc,
                       referencelocation: refloc,
                       textsize: {silktextheight,silktextwidth},
                       textwidth: silktextthickness,
                       descr: descr,
                       tags: tags,
                       isSMD: false,
                       features: features)
      IO.binwrite file, "#{m}"
      File.close file
    end


  def build(defaults, overrides, output_base_directory, config_base_directory) do
    output_directory = "#{output_base_directory}/#{@library_name}.pretty"
    File.mkdir(output_directory)

    # Note that for the headers we'll just define the pin layouts (counts)
    # programatically.  We won't use the device sections of the config file
    # to define the number of pins or rows.


    # Override default parameters for this library (set of modules) and add
    # device specific values.  The override based on command line parameters
    # (passed in via `overrides` variable)
    temp = YamlElixir.read_from_file("#{config_base_directory}/#{@device_file_name}")
    p = Enum.map(temp["defaults"], fn({k,v})-> Map.put(%{}, String.to_atom(k), v) end)
        |> Enum.reduce(fn(data, acc)-> Map.merge(data,acc) end)
    p2 = Map.merge defaults, p
    params = Map.merge p2, overrides

    pinpitch = params[:pinpitch]
    devices = for pincount <- [2,3,4,5,6,7,8,9,10,11,12,13,14,15,20,30,40], do: pincount
    Enum.map(devices, fn pincount ->
                  filename = "#{output_directory}/DF13-#{pincount}P-#{round(pinpitch*100.0)}DS.kicad_mod"
                  create_mod(params, pincount, 1, filename)
                end)
    :ok
  end

end
