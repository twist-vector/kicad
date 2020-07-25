require FootprintSupport
require Integer

defmodule Footprints.NanofitHeaderPTH do
  alias Footprints.Components, as: Comps

  def create_mod(params, pincount, rowcount, filename) do
      silktextheight    = params[:silktextheight]
      silktextwidth     = params[:silktextwidth]
      silktextthickness = params[:silktextthickness]
      silkoutlinewidth  = params[:silkoutlinewidth]
      courtyardmargin   = params[:courtyardmargin]
      pinpitch          = params[:pinpitch]
      maskmargin        = params[:soldermaskmargin]

      # All pins aligned at y=0
      #  lower face at y=1.21
      #  upper face at y=2.19
      lower    = 1.74
      upper    = -1.74
      tabLower = 4.6
      tabWidth = 5.2

      bodylen  = pinpitch*(pincount-1) + 3.44 # extent in x

      # Bounding "courtyard" for the device
      crtydlength = bodylen + 2*courtyardmargin
      courtyard = Comps.box(ll: {-crtydlength/2, upper-courtyardmargin},
                            ur: { crtydlength/2, tabLower+courtyardmargin},
                            layer: "F.CrtYd", width: silkoutlinewidth)

      # The grid of pads.  We'll call the common function from the PTHHeader
      # module for each pin location.
      pads = for pin <- 1..pincount, do:
               Footprints.PTHHeaderSupport.make_pad(params, pin, 1, pincount, 1, "oval", maskmargin)

      # Alignment tab hole
      x = if Integer.is_even(pincount) do 0
          else -1.25
          end
      y = 1.34
      align = [Comps.pad(:pth, "tab", "oval", {x, y}, {1.29,1.29}, 1.3, 0)]

      # Outline
      outline = [Comps.line(start: {-bodylen/2,lower}, end: {bodylen/2,lower}, layer: "F.SilkS", width: silkoutlinewidth),
                 Comps.line(start: {-bodylen/2,upper}, end: {bodylen/2,upper}, layer: "F.SilkS", width: silkoutlinewidth),
                 Comps.line(start: {-bodylen/2,upper}, end: {-bodylen/2,lower}, layer: "F.SilkS", width: silkoutlinewidth),
                 Comps.line(start: {bodylen/2,upper}, end: {bodylen/2,lower}, layer: "F.SilkS", width: silkoutlinewidth),
                 # The latch outline
                 Comps.line(start: {-tabWidth/2,tabLower}, end: {tabWidth/2,tabLower}, layer: "F.SilkS", width: silkoutlinewidth),
                 Comps.line(start: {-tabWidth/2,lower}, end: {-tabWidth/2,tabLower}, layer: "F.SilkS", width: silkoutlinewidth),
                 Comps.line(start: {tabWidth/2,lower}, end: {tabWidth/2,tabLower}, layer: "F.SilkS", width: silkoutlinewidth),
                 Comps.line(start: {-tabWidth/6,lower+silkoutlinewidth}, end: {tabWidth/6,lower+silkoutlinewidth}, layer: "F.SilkS", width: silkoutlinewidth),
                ]


      # Put all the module pieces together, create, and write the module
      features = List.flatten(pads) ++ courtyard ++ outline ++ align

      refloc   = {-crtydlength/2 - 0.75*silktextheight, 0}
      valloc   = { crtydlength/2 + 0.75*silktextheight, 0}
      name     = "NanofitHeader_#{pincount}x#{rowcount}"
      descr    = "#{pincount}x#{rowcount} 0.10in (2.54 mm) spacing Molex Nanofit header"
      tags     = ["Molex", "PTH", "shrouded", "header"]
      textsize = {silktextheight,silktextwidth}

      m = Comps.module(name, descr, features, refloc, valloc, textsize, silktextthickness, tags)

      {:ok, file} = File.open filename, [:write]
      IO.binwrite file, "#{m}"
      File.close file
    end


  def build(library_name, device_file_name, defaults, overrides, output_base_directory, config_base_directory) do
    output_directory = "#{output_base_directory}/#{library_name}.pretty"
    File.mkdir(output_directory)

    # Override default parameters for this library (set of modules) and add
    # device specific values.  The override based on command line parameters
    # (passed in via `overrides` variable)
    params = FootprintSupport.make_params("#{config_base_directory}/#{device_file_name}", defaults, overrides)

    # Note that for the headers we'll just define the pin layouts (counts)
    # programatically.  We won't use the device sections of the config file
    # to define the number of pins or rows.
    pinpitch = params[:pinpitch]
    devices = for pincount <- 2..8, rowcount <- 1..1, pincount>=rowcount, do: {pincount,rowcount}
    Enum.map(devices, fn {pincount,rowcount} ->
                  filename = "#{output_directory}/NanofitHDR#{round(pinpitch*100.0)}P#{pincount}x#{rowcount}.kicad_mod"
                  create_mod(params, pincount, rowcount, filename)
                end)

    :ok
  end

end
