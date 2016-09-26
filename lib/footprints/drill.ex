defmodule Footprints.Drills do
  alias Footprints.Components, as: Comps

  @library_name "Drills"


  def create_mod(params, name, m_text, drilldia, filename) do
    silktextheight    = params[:silktextheight]
    silktextwidth     = params[:silktextwidth]
    silktextthickness = params[:silktextthickness]
    silkoutlinewidth  = params[:silkoutlinewidth]
    courtyardmargin   = params[:courtyardmargin]
    courtoutlinewidth = params[:courtoutlinewidth]

    padsize = drilldia * 1.75
    pad = Comps.padPTH(name: "1", shape: "oval", at: {0,0}, size: {padsize,padsize}, drill: drilldia)

    # Bounding "courtyard" for the device
    crtydsize = padsize + 2*courtyardmargin
    courtyard = Comps.box(ll: {-crtydsize/2,  crtydsize/2},
                          ur: { crtydsize/2, -crtydsize/2},
                          layer: "F.CrtYd", width: courtoutlinewidth)

    outline = [Comps.circle(center: {0,0}, radius: padsize/2+2*silkoutlinewidth, layer: "F.SilkS", width: silkoutlinewidth),
               Comps.circle(center: {0,0}, radius: padsize/2+2*silkoutlinewidth, layer: "B.SilkS", width: silkoutlinewidth)]

    # Put all the module pieces together, create, and write the module
    features = [pad, courtyard] ++ outline

    descr = "Drill for an #{m_text} size screw"
    refloc = {-crtydsize/2 - 0.75*silktextheight, 0, 90}
    valloc = { crtydsize/2 + 0.75*silktextheight, 0, 90}
    {:ok, file} = File.open filename, [:write]
    m = Comps.module(name: name,
                     valuelocation: valloc,
                     referencelocation: refloc,
                     textsize: {silktextheight,silktextwidth},
                     textwidth: silktextthickness,
                     descr: descr,
                     tags: ["PTH", "drill"],
                     isSMD: false,
                     features: features)
    IO.binwrite file, "#{m}"
    File.close file
  end


  def build(defaults, overrides, output_base_directory, _config_base_directory) do
    output_directory = "#{output_base_directory}/#{@library_name}.pretty"
    File.mkdir(output_directory)

    # Note that for the drills we'll just define the drill diameters
    # programatically.  We won't use the device sections of the config file
    # to define the number of pins or rows.


    # Override default parameters for this library (set of modules) and add
    # device sqpecific values.  The override based on command line parameters
    # (passed in via `overrides` variable)
    params = Map.merge defaults, overrides

    m_sizes = [0.5, 0.75, 1, 1.5, 1.6, 1.8, 2, 2.2, 2.5, 3, 3.5, 3.8, 4, 4.5, 5, 5.5, 6, 7, 8, 9, 10]
    Enum.map(m_sizes, fn s ->
                  m_text = to_string List.flatten( :io_lib.format("M~w", [s]) )
                  drilldia = 1.1 * s
                  name = "DRILL_#{round(s*10)}D"
                  filename = "#{output_directory}/#{name}.kicad_mod"
                  create_mod(params, name, m_text, drilldia, filename)
                end)

    :ok
  end

end
