defmodule Footprints.SOIC do
  alias Footprints.Components, as: Comps



  #
  # def create_mod(params, name, descr, bodylen, bodywid, totalwid, pinwidth,
  #                epadlen, epadwid, pincount, tags, filename) do
  #   #
  #   # Device oriented left-to-right:  Body length is then in the KiCad x
  #   # direction, body width is in the y direction.
  #   #
  #   silktextheight    = params[:silktextheight]
  #   silktextwidth     = params[:silktextwidth]
  #   silkoutlinewidth  = params[:silkoutlinewidth]
  #   courtoutlinewidth = params[:courtoutlinewidth]
  #   docoutlinewidth   = params[:docoutlinewidth]
  #   toefillet         = params[:toefillet]
  #   heelfillet        = params[:heelfillet]
  #   sidefillet        = params[:sidefillet]
  #   pinlentol         = params[:pinlentol] # pin length is in the x direction
  #   placetol          = params[:placetol]
  #   lentol            = params[:lentol]
  #   fabtol            = params[:fabtol]
  #   widtol            = params[:widtol]
  #   courtyardmargin   = params[:courtyardmargin]
  #
  #   totaltol  = :math.sqrt(:math.pow(pinlentol, 2)+:math.pow(fabtol, 2)+:math.pow(placetol, 2))
  #
  #   xmin = bodylen - lentol # Minimum possible body length
  #   xmax = bodylen + lentol # Maximum possible body length
  #
  #   minInsideLengthX  = xmin - 2*(legland+pinlentol)
  #   maxOutsideLengthX = xmax
  #   maxExtentY = bodywid + widtol
  #
  #   padSizeX = (maxOutsideLengthX - minInsideLengthX)/2 + heelfillet + toefillet + totaltol
  #   padSizeY = maxExtentY + 2*sidefillet + totaltol
  #
  #   padCenterX = minInsideLengthX/2 + padSizeX/2 - heelfillet
  #   padCenterY = 0;
  #
  #   crtydSizeX = 2*(max(padCenterX+padSizeX/2, bodylen/2) + courtyardmargin)
  #   crtydSizeY = 2*(max(padCenterY+padSizeY/2, bodywid/2) + courtyardmargin)
  #
  #   pads = [Comps.padSMD(name: "1", shape: "rect", at: {-padCenterX, padCenterY}, size: {padSizeX, padSizeY}),
  #           Comps.padSMD(name: "2", shape: "rect", at: { padCenterX, padCenterY}, size: {padSizeX, padSizeY})]
  #
  #   if polarized do
  #     silk = [Comps.line(start: {-padCenterX-padSizeX/2, -padSizeY/2-2*silkoutlinewidth},
  #                          end: { minInsideLengthX/2, -padSizeY/2-2*silkoutlinewidth},
  #                        layer: "F.SilkS",
  #                        width: silkoutlinewidth)] ++
  #            [Comps.line(start: {-padCenterX-padSizeX/2, padSizeY/2+2*silkoutlinewidth},
  #                          end: { minInsideLengthX/2, padSizeY/2+2*silkoutlinewidth},
  #                        layer: "F.SilkS",
  #                        width: silkoutlinewidth)] ++
  #             [Comps.circle(center: {-padCenterX-padSizeX/2-0.25,0}, radius: 0.05,
  #                           layer: "F.SilkS", width: silkoutlinewidth)]
  #   else
  #     silk = [Comps.line(start: {-minInsideLengthX/2, -padSizeY/2-2*silkoutlinewidth},
  #                          end: { minInsideLengthX/2, -padSizeY/2-2*silkoutlinewidth},
  #                        layer: "F.SilkS",
  #                        width: silkoutlinewidth)] ++
  #            [Comps.line(start: {-minInsideLengthX/2, padSizeY/2+2*silkoutlinewidth},
  #                          end: { minInsideLengthX/2, padSizeY/2+2*silkoutlinewidth},
  #                        layer: "F.SilkS",
  #                        width: silkoutlinewidth)]
  #   end
  #   courtyard = Footprints.Components.box(ll: {-crtydSizeX/2,crtydSizeY/2},
  #                                         ur: {crtydSizeX/2,-crtydSizeY/2},
  #                                         layer: "F.CrtYd", width: courtoutlinewidth)
  #
  #   outline = Footprints.Components.box(ll: {-bodylen/2,bodywid/2},
  #                                       ur: {bodylen/2,-bodywid/2},
  #                                       layer: "Dwgs.User", width: docoutlinewidth) ++
  #             Footprints.Components.box(ll: {-bodylen/2,bodywid/2},
  #                                       ur: {-bodylen/2+legland,-bodywid/2},
  #                                       layer: "Dwgs.User", width: docoutlinewidth) ++
  #             Footprints.Components.box(ll: {bodylen/2-legland,bodywid/2},
  #                                       ur: {bodylen/2,-bodywid/2},
  #                                       layer: "Dwgs.User", width: docoutlinewidth)
  #
  #
  #   features = pads ++ [Enum.join(courtyard, "\n  ")] ++
  #       [Enum.join(outline, "\n  ")] ++ silk
  #
  #   refloc      = {-crtydSizeX/2 - 0.75*silktextheight, 0, 90}
  #   valloc      = { crtydSizeX/2 + 0.75*silktextheight, 0, 90}
  #   m = Comps.module(name: name,
  #                    valuelocation: valloc,
  #                    referencelocation: refloc,
  #                    textsize: {silktextheight,silktextwidth},
  #                    textwidth: silkoutlinewidth,
  #                    descr: descr,
  #                    tags: tags,
  #                    isSMD: false,
  #                    features: features)
  #   {:ok, file} = File.open filename, [:write]
  #   IO.binwrite file, "#{m}"
  #   File.close file
  # end
  #
  #
  # def build(output_base_directory, library_name) do
  #   output_directory = "#{output_base_directory}/#{library_name}.pretty"
  #
  #   File.mkdir(output_directory)
  #
  #   # Read in default values
  #   defaults = Footprints.Xml.read_defaults(%{}, "global_defaults.xml")
  #
  #   # Append specific parameters for this library (set of modules)
  #   params = Map.merge defaults, %{}
  #
  #   sizes = [#{ bodylen, bodywid, totalwid, pinwidth, epadlen, epadwid, pincount }
  #
  #           ]
  #
  #   Enum.map( sizes, fn {bodylen, bodywid, totalwid, pinwidth, epadlen, epadwid, pincount} ->
  #       filename = "#{output_directory}/SOIC-#{code}.kicad_mod"
  #       tags = ["SMD", "SOIC"]
  #       create_mod(params, "#{pincount}_SOIC", "#{pincount} pin SOIC chip",
  #                  bodylen, bodywid, totalwid, pinwidth,
  #                  epadlen, epadwid, pincount, tags, filename)
  #     end
  #   )
  #
  #
  #   :ok
  # end

end
