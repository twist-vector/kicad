
defmodule Footprints do

  def main(args) do
    args
    |> parse_args
    |> process
  end

  def process([]) do
    IO.puts "Usage: footprints --dir=[output directory]"
  end

  def process(options) do
    IO.puts "Using #{options[:dir]}"

    Footprints.PTHHeader.build(options[:dir], "PTH_Headers")
    Footprints.PTHHeaderRA.build(options[:dir], "PTH_Headers")
    Footprints.Passives.build(options[:dir], "SMD_Passives")
    Footprints.Diodes.build(options[:dir], "SMD_Diodes")
  end



  defp parse_args(args) do
    {options, _, _} = OptionParser.parse(args,
      strict: [dir: :string]
    )
    options
  end

end
