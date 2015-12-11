defmodule Footprints.Diodes do
  alias Footprints.Components, as: Comps



  def create_mod(params, name, descr, bodylen, bodywid, legland, tags, filename) do
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
    pinlentol         = params[:pinlentol] # pin length is in the x direction
    placetol          = params[:placetol]
    lentol            = params[:lentol]
    fabtol            = params[:fabtol]
    widtol            = params[:widtol]
    courtyardmargin   = params[:courtyardmargin]

    totaltol  = :math.sqrt(:math.pow(pinlentol, 2)+:math.pow(fabtol, 2)+:math.pow(placetol, 2))

    xmin = bodylen - lentol # Minimum possible body length
    xmax = bodylen + lentol # Maximum possible body length

    minInsideLengthX  = xmin - 2*(legland+pinlentol)
    maxOutsideLengthX = xmax
    maxExtentY = bodywid + widtol

    padSizeX = (maxOutsideLengthX - minInsideLengthX)/2 + heelfillet + toefillet + totaltol
    padSizeY = maxExtentY + 2*sidefillet + totaltol

    padCenterX = minInsideLengthX/2 + padSizeX/2 - heelfillet
    padCenterY = 0;

    crtydSizeX = 2*(max(padCenterX+padSizeX/2, bodylen/2) + courtyardmargin)
    crtydSizeY = 2*(max(padCenterY+padSizeY/2, bodywid/2) + courtyardmargin)

    pads = [Comps.padSMD(name: "1", shape: "rect", at: {-padCenterX, padCenterY}, size: {padSizeX, padSizeY}),
            Comps.padSMD(name: "2", shape: "rect", at: { padCenterX, padCenterY}, size: {padSizeX, padSizeY})]

    silk = [Comps.line(start: {-padCenterX-padSizeX/2, -padSizeY/2-2*silkoutlinewidth},
                         end: { minInsideLengthX/2, -padSizeY/2-2*silkoutlinewidth},
                       layer: "F.SilkS",
                       width: silkoutlinewidth)] ++
           [Comps.line(start: {-padCenterX-padSizeX/2, padSizeY/2+2*silkoutlinewidth},
                         end: { minInsideLengthX/2, padSizeY/2+2*silkoutlinewidth},
                       layer: "F.SilkS",
                       width: silkoutlinewidth)] ++
            [Comps.circle(center: {-padCenterX-padSizeX/2-0.25,0}, radius: 0.05,
                          layer: "F.SilkS", width: silkoutlinewidth)] ++
            [Comps.line(start: {-minInsideLengthX/2+silkoutlinewidth,-padSizeY/2},
                          end: {-minInsideLengthX/2+silkoutlinewidth,padSizeY/2},
                        layer: "F.SilkS", width: silkoutlinewidth)]

    courtyard = Footprints.Components.box(ll: {-crtydSizeX/2,crtydSizeY/2},
                                          ur: {crtydSizeX/2,-crtydSizeY/2},
                                          layer: "F.CrtYd", width: courtoutlinewidth)

    outline = Footprints.Components.box(ll: {-bodylen/2,bodywid/2},
                                        ur: {bodylen/2,-bodywid/2},
                                        layer: "Dwgs.User", width: docoutlinewidth) ++
              Footprints.Components.box(ll: {-bodylen/2,bodywid/2},
                                        ur: {-bodylen/2+legland,-bodywid/2},
                                        layer: "Dwgs.User", width: docoutlinewidth) ++
              Footprints.Components.box(ll: {bodylen/2-legland,bodywid/2},
                                        ur: {bodylen/2,-bodywid/2},
                                        layer: "Dwgs.User", width: docoutlinewidth)


    features = pads ++ [Enum.join(courtyard, "\n  ")] ++ silk ++
                 [Enum.join(outline, "\n  ")]

    refloc      = {-crtydSizeX/2 - 0.75*silktextheight, 0, 90}
    valloc      = { crtydSizeX/2 + 0.75*silktextheight, 0, 90}
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


  def build(output_base_directory, library_name) do
    output_directory = "#{output_base_directory}/#{library_name}.pretty"

    File.mkdir(output_directory)

    # Read in default values
    defaults = Footprints.Xml.read_defaults(%{}, "global_defaults.xml")

    # Append specific parameters for this library (set of modules)
    params = Map.merge defaults, %{}

    sizes = [#{ len, wid, legland, metriccode, imperialcode }
              { 0.6, 0.3, 0.10, "0603", "0201" },
              { 1.0, 0.5, 0.35, "1005", "0402" },
              {	1.6, 0.8, 0.35, "1608", "0603" },
              {	2.0, 1.2, 0.50, "2012", "0805" },
              {	2.5, 2.0, 0.50, "2520", "1008" },
              {	2.8, 2.8, 0.50, "2828", "1111" },
              {	3.2, 1.6, 0.50, "3216", "1206" },
              {	3.2, 2.5, 0.50, "3225", "1210" },
              {	3.5, 2.4, 0.50, "3524", "1410" },
              {	4.5, 1.2, 0.50, "4512", "1805" },
              {	4.5, 2.0, 0.60, "4520", "1808" },
              {	4.5, 3.2, 0.60, "4532", "1812" },
              {	5.7, 2.8, 0.60, "5728", "2211" },
              {	5.7, 5.0, 0.60, "5750", "2220" },
              {	6.0, 5.0, 0.80, "6050", "2420" },
              {	7.5, 6.3, 0.80, "7563", "3025" }
            ]

    Enum.map( sizes, fn {len, wid, legland, metriccode, imperialcode} ->
        filename = "#{output_directory}/DIODEC-#{metriccode}-#{imperialcode}.kicad_mod"
        tags = ["SMD", "diode", metriccode]
        create_mod(params, "#{len}x#{wid}_chip_diode",
                   "#{len}x#{wid} (#{metriccode} metric) chip diode",
                   len, wid, legland, tags, filename)
      end
    )


    :ok
  end

end
