defmodule Footprints.PTHHeaderSupport do
  alias Footprints.Components, as: Comps

  def make_pin_outline(pinpitch, i, layer, {xc,yc}) do
    numpoints  = 8
    angle      = 180/numpoints * :math.pi/180.0

    bodyrad    = pinpitch / :math.cos(angle)/2.0;
    thetaStart = i*2.0*:math.pi/numpoints + angle
    thetaEnd   = (i+1)*2.0*:math.pi/numpoints + angle
    dxStart    = bodyrad * :math.cos(thetaStart)
    dyStart    = bodyrad * :math.sin(thetaStart)
    dxEnd      = bodyrad * :math.cos(thetaEnd)
    dyEnd      = bodyrad * :math.sin(thetaEnd)
    Comps.line(start: {xc+dxStart,yc+dyStart},
               end: {xc+dxEnd,yc+dyEnd},
               layer: layer, width: 0.1)
  end



  def make_outline(params, pincount, rowcount, layer) do
    pinpitch        = params[:pinpitch]
    rowpitch        = params[:rowpitch]

    row = 1
    bottom = for pin <- 1..pincount do
      xc = -((pincount-1)/2*pinpitch) + (pin-1)*pinpitch
      yc = rowpitch*(rowcount-1)/2.0 - (row-1)*rowpitch
      edges = if rowcount == 1  and pincount == 1 do
                0..7
              else
                case pin do
                   1 -> [0,1,2,3,4]
           ^pincount -> [0,1,2,6,7]
                   _ -> [0,1,2]
                end
              end
       for n <- edges, do: make_pin_outline(pinpitch, n,layer,{xc,yc})
    end

    row = rowcount
    top = for pin <- 1..pincount do
      xc = -((pincount-1)/2*pinpitch) + (pin-1)*pinpitch
      yc = rowpitch*(rowcount-1)/2.0 - (row-1)*rowpitch
      edges = case pin do
                   1 -> [2,3,4,5,6]
           ^pincount -> [0,4,5,6,7]
                   _ -> [4,5,6]
              end
       for n <- edges, do: make_pin_outline(pinpitch, n,layer,{xc,yc})
    end

    rest = if rowcount > 1 do
      for row <- 2..rowcount-1 do
         for pin <- 1..pincount do
            xc = -((pincount-1)/2*pinpitch) + (pin-1)*pinpitch
            yc = rowpitch*(rowcount-1)/2.0 - (row-1)*rowpitch
            edges = case pin do
                         1 -> [2,3,4]
                 ^pincount -> [0,6,7]
                         _ -> []
                    end
             for n <- edges, do: make_pin_outline(pinpitch, n,layer,{xc,yc})
          end
        end
    else
      []
    end

    List.flatten(bottom) ++ List.flatten(top) ++ List.flatten(rest)
  end



  def make_pad(params, pin, row, pincount, rowcount, shape \\ "oval") do
    pinpitch        = params[:pinpitch]
    rowpitch        = params[:rowpitch]
    padwidth        = params[:padwidth]
    padheight       = params[:padheight]
    drilldia        = params[:drilldia]

    xc = -((pincount-1)/2*pinpitch) + (pin-1)*pinpitch
    yc = rowpitch*(rowcount-1)/2.0 - (row-1)*rowpitch
    pn = (pin-1)*rowcount + row

    Comps.padPTH(name: "#{pn}", shape: shape, at: {xc,yc},
                 size: {padwidth,padheight}, drill: drilldia)
  end


end
