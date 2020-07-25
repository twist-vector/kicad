defmodule Footprints.Combicon do
  alias Footprints.Components, as: Comps


  def create_mod(params, pincount, filename) do
      silktextheight    = params[:silktextheight]
      silktextwidth     = params[:silktextwidth]
      silktextthickness = params[:silktextthickness]
      silkoutlinewidth  = params[:silkoutlinewidth]
      courtyardmargin   = params[:courtyardmargin]
      pinpitch          = params[:pinpitch]
      drilldia          = params[:drilldia]
      maskmargin        = params[:soldermaskmargin]

      bodyedgex         = 2.5
      bodyoffsetx       = 1.5
      bodyoffsety       = 1.3

      bodylen     = pinpitch*(pincount-1) + bodyedgex + bodyoffsetx  # extent in x
      bodywid     = 12 # extent in y

      # Bounding "courtyard" for the device
      crtydlength = bodylen + 2*courtyardmargin
      crtydwidth  = bodywid + 2*courtyardmargin
      ll = {-crtydlength/2-bodyoffsetx/2,  crtydwidth/2-bodyoffsety}
      ur = { crtydlength/2-bodyoffsetx/2, -crtydwidth/2-bodyoffsety}
      courtyard = Comps.box(ll, ur, "F.CrtYd", silkoutlinewidth)

      # The grid of pads/pins.  We'll call the common function from the PTHHeader
      # module for each pin location.
      pads = for pin <- 1..pincount, do:
               Footprints.PTHHeaderSupport.make_pad(params, pin, 1, pincount, 1, "oval", maskmargin)

      # Add the header outline.
      frontSilkBorder = [Comps.box({-bodylen/2-bodyoffsetx/2,  bodywid/2-bodyoffsety},
                                   { bodylen/2-bodyoffsetx/2, -bodywid/2-bodyoffsety},
                                   "F.SilkS", silkoutlinewidth),
                         Comps.line({-bodylen/2-bodyoffsetx/2+bodyoffsetx, bodywid/2-bodyoffsety},
                                   {-bodylen/2-bodyoffsetx/2+bodyoffsetx,-bodywid/2-bodyoffsety},
                                   "F.SilkS", silkoutlinewidth),
                         Comps.line({-bodylen/2-bodyoffsetx/2+bodyoffsetx, bodyoffsety+1.5*drilldia},
                                    {bodylen/2-bodyoffsetx/2, bodyoffsety+1.5*drilldia},
                                    "F.SilkS", silkoutlinewidth),
                         Comps.line({-bodylen/2-bodyoffsetx/2+bodyoffsetx, -2*drilldia},
                                    {bodylen/2-bodyoffsetx/2, -2*drilldia},
                                    "F.SilkS", silkoutlinewidth)]
      wireEntryMarks = for pin <- 1..pincount do
                         xc = -((pincount-1)/2*pinpitch) + (pin-1)*pinpitch
                         yc = bodyoffsety + drilldia/2
                         Comps.circle({xc,yc}, drilldia/2, "F.SilkS", silkoutlinewidth)
                       end
      releaseMarks = for pin <- 1..pincount do
                       llx = -((pincount-1)/2*pinpitch) + (pin-1)*pinpitch - drilldia/2
                       lly = -2.5*drilldia
                       urx = llx + drilldia
                       ury = -bodywid/2-bodyoffsety + drilldia
                       Comps.box({llx,lly}, {urx,ury}, "F.SilkS", silkoutlinewidth)
                     end
      releaseArrows = for pin <- 1..pincount do
                        lx = -((pincount-1)/2*pinpitch) + (pin-1)*pinpitch
                        ly = bodyoffsety + drilldia/2 + 2.25*drilldia
                        ux = lx
                        uy = bodyoffsety + drilldia/2 + 1.5*drilldia
                        [Comps.line({lx, ly}, {ux,uy}, "Dwgs.User", silkoutlinewidth),
                         Comps.line({ux-0.25, uy+0.25}, {ux,uy}, "Dwgs.User", silkoutlinewidth),
                         Comps.line({ux+0.25, uy+0.25}, {ux,uy}, "Dwgs.User", silkoutlinewidth)]
                      end


      # Put all the module pieces together, create, and write the module
      features = List.flatten(pads) ++ courtyard ++ frontSilkBorder ++
                       wireEntryMarks ++ releaseMarks ++ releaseArrows

      refloc   = {-crtydlength/2-bodyoffsetx/2 - 0.75*silktextheight, 0}
      valloc   = { crtydlength/2-bodyoffsetx/2 + 0.75*silktextheight, 0}
      textsize = {silktextheight,silktextwidth}
      name     = "Combicon_Header_#{pincount}"
      descr    = "#{pincount} Spring-Cage PCB Wire-to-Board Termination Blocks"
      tags     = ["PTH", "wire2board", "header", "COMBICON", "PTSA"]
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
    devices = for pincount <- 2..24, do: {pincount}
    Enum.map(devices, fn {pincount} ->
                  filename = "#{output_directory}/COMBICON_HDR#{round(pinpitch*100.0)}P#{pincount}.kicad_mod"
                  create_mod(params, pincount, filename)
                end)
    :ok
  end

end
