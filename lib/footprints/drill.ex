defmodule Footprints.Drills do
  alias Footprints.Components, as: Comps


  def create_mod(params, name, descr, drilldia, filename) do
    silktextheight    = params[:silktextheight]
    silktextwidth     = params[:silktextwidth]
    silktextthickness = params[:silktextthickness]
    silkoutlinewidth  = params[:silkoutlinewidth]
    courtyardmargin   = params[:courtyardmargin]
    courtoutlinewidth = params[:courtoutlinewidth]
    padscale          = params[:padscale]
    maskmargin        = params[:soldermaskmargin]

    padsize = drilldia * padscale
    pad = Comps.pad(:pth, "1", "oval", {0, 0}, {padsize,padsize}, drilldia, maskmargin)

    # Bounding "courtyard" for the device
    crtydsize = padsize + 2*courtyardmargin
    courtyard = Comps.box({-crtydsize/2,  crtydsize/2},
                          { crtydsize/2, -crtydsize/2},
                          "F.CrtYd", courtoutlinewidth)

    outline = [Comps.circle({0,0}, padsize/2+2*silkoutlinewidth, "F.SilkS", silkoutlinewidth),
               Comps.circle({0,0}, padsize/2+2*silkoutlinewidth, "B.SilkS", silkoutlinewidth)]

    # Put all the module pieces together, create, and write the module
    features = [pad, courtyard] ++ outline

    refloc   = {-crtydsize/2 - 0.75*silktextheight, 0}
    valloc   = { crtydsize/2 + 0.75*silktextheight, 0}
    textsize = {silktextheight,silktextwidth}
    tags     = ["PTH", "drill"]
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

    # Note that for the drills we'll just define the drill diameters
    # programatically.  We won't use the device sections of the config file
    # to define the number of pins or rows.  
   
    # The metrix "M" sizes
    m_sizes = [1, 1.5, 1.6, 1.8, 2, 2.2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5, 6, 7, 8, 9, 10]
    
    # We'll use the "standard" clearance as defined here 
    #     https://littlemachineshop.com/images/gallery/PDF/TapDrillSizes.pdf
    Enum.map(m_sizes, fn s ->
                  m_text = to_string List.flatten( :io_lib.format("M~w", [s]) )
                  std_descr = "Standard clearance drill for an #{m_text} size screw"
                  drilldia = 1.1 * s
                  name = "DRILL_#{round(s*10)}D"
                  filename = "#{output_directory}/#{name}.kicad_mod"
                  create_mod(params, name, std_descr, drilldia, filename)
                end)

    # ... and the  "tight" clearance
    Enum.map(m_sizes, fn s ->
                  m_text = to_string List.flatten( :io_lib.format("M~w", [s]) )
                  tght_descr = "Tight clearance drill for an #{m_text} size screw"
                  drilldia = 1.06 * s
                  name = "DRILL_TGHT_#{round(s*10)}D"
                  filename = "#{output_directory}/#{name}.kicad_mod"
                  create_mod(params, name, tght_descr, drilldia, filename)
                end)

    :ok
  end

end
