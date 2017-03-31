defmodule Footprints.SMDHeaderSupport do
  alias Footprints.Components, as: Comps


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
          end
        end
    else
      []
    end

    List.flatten(bottom) ++ List.flatten(top) ++ List.flatten(rest)
  end



  def make_pad(params, pin, row, pincount, rowcount, shape \\ "oval", maskmargin, pastemargin) do
    pinpitch        = params[:pinpitch]
    rowpitch        = params[:rowpitch]
    padwidth        = params[:padwidth]
    padheight       = params[:padheight]

    xc = -((pincount-1)/2*pinpitch) + (pin-1)*pinpitch
    yc = rowpitch*(rowcount-1)/2.0 - (row-1)*rowpitch
    pn = (pin-1)*rowcount + row

    Comps.padSMD(name: "#{pn}", shape: shape, at: {xc,yc},
                 size: {padwidth,padheight}, pastemargin: pastemargin,
                 maskmargin: maskmargin)
  end


end
