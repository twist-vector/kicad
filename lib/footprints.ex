
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

    Footprints.PTHHeader.build(options[:dir], "Headers")
    Footprints.PTHHeaderRA.build(options[:dir], "Headers")
  end



  defp parse_args(args) do
    {options, _, _} = OptionParser.parse(args,
      strict: [dir: :string]
    )
    options
  end

end
