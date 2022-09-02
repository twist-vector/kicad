require FootprintSupport

defmodule Footprints.PTHHeader do
  alias Footprints.Components, as: Comps

  def create_mod(params, pincount, rowcount, filename) do
      silktextheight    = params[:silktextheight]
      silktextwidth     = params[:silktextwidth]
      silktextthickness = params[:silktextthickness]
      silkoutlinewidth  = params[:silkoutlinewidth]
      courtyardmargin   = params[:courtyardmargin]
      pinpitch          = params[:pinpitch]
      rowpitch          = params[:rowpitch]
      padwidth          = params[:padwidth]
      padheight         = params[:padheight]
      maskmargin        = params[:soldermaskmargin]

      bodylen     = pinpitch*(pincount-1) + padwidth  # extent in x
      bodywid     = rowpitch*(rowcount-1) + padheight # extent in y

      # Bounding "courtyard" for the device
      crtydlength = (bodylen + padheight) + courtyardmargin
      crtydwidth  = (bodywid + padwidth) + courtyardmargin
      courtyard = Comps.box({-crtydlength/2,  crtydwidth/2},
                            { crtydlength/2, -crtydwidth/2},
                            "F.CrtYd", silkoutlinewidth)

      # The grid of pads.  We'll call the common function from the PTHHeaderSupport
      # module for each pin location.
      pads = for row <- 1..rowcount, do:
               for pin <- 1..pincount, do:
                 Footprints.PTHHeaderSupport.make_pad(params, pin, row, pincount, rowcount, "oval", maskmargin)

      # Add the header outline.  The PTHHeaderSupport function draws the outside boundary
      # rather than the outline of each individual pin.
      frontSilkBorder = Footprints.PTHHeaderSupport.make_outline(params, pincount, rowcount, "F.SilkS")
      backSilkBorder = Footprints.PTHHeaderSupport.make_outline(params, pincount, rowcount, "B.SilkS")

      # Pin 1 marker (circle)
      xcc = bodylen/2 + padwidth/4
      ycc = bodywid/2 + padheight/4
      cFront = Comps.circle({-xcc,ycc}, silkoutlinewidth, "F.SilkS", silkoutlinewidth)


      # Put all the module pieces together, create, and write the module
      features = List.flatten(pads) ++ courtyard ++ frontSilkBorder ++ backSilkBorder ++ [cFront]

      refloc      = {0,0}   #{-crtydlength/2 - 0.75*silktextheight, 0}
      valloc      = {0,0}   #{ crtydlength/2 + 0.75*silktextheight, 0}
      m = Comps.module("Header_#{pincount}x#{rowcount}",
                       "#{pincount}x#{rowcount} 0.10in (2.54 mm) spacing unshrouded header",
                       features,
                       refloc,
                       valloc,
                       {silktextheight,silktextwidth},
                       silktextthickness)

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
    devices = for pincount <- 1..40, rowcount <- 1..3, pincount>=rowcount, do: {pincount,rowcount}
    Enum.map(devices, fn {pincount,rowcount} ->
                  filename = "#{output_directory}/HDR#{round(pinpitch*100.0)}P#{pincount}x#{rowcount}.kicad_mod"
                  create_mod(params, pincount, rowcount, filename)
                end)

    :ok
  end

end
