
defmodule Footprints do

  def main(args) do
    args
    |> parse_args
    |> process
  end

  # def process([]) do
  #   IO.puts "Usage: footprints --dir=[output directory]  --cfg=[configuration directory]"
  # end

  def process(options) do
    # Set defaults if no command line arguments
    if !options[:dir], do: output_base_directory = "DATA",
    else:                  output_base_directory = options[:dir]
    if !options[:cfg], do: config_base_directory = "devices",
    else:                  config_base_directory = options[:dir]

    IO.puts "Input config directory:   #{config_base_directory}"
    IO.puts "Output library directory: #{output_base_directory}"

    # Read in default values
    a = YamlElixir.read_from_file("#{config_base_directory}/global_defaults.yml")
    defaults = Enum.map(a["defaults"], fn({k,v})-> Map.put(%{}, String.to_atom(k), v) end)
               |> Enum.reduce(fn(data, acc)-> Map.merge(data,acc) end)


    Footprints.PTH254Header.build(defaults, output_base_directory, config_base_directory)
    Footprints.PTH254HeaderRA.build(defaults, output_base_directory, config_base_directory)
    Footprints.PTH127Header.build(defaults, output_base_directory, config_base_directory)
    Footprints.PTH127HeaderRA.build(defaults, output_base_directory, config_base_directory)
    Footprints.Passives.build(defaults, output_base_directory, config_base_directory)
    Footprints.Diodes.build(defaults, output_base_directory, config_base_directory)
  end



  defp parse_args(args) do
    {options, _, _} = OptionParser.parse(args,
      switches: [dir: :string, cfg: :string]
    )
    options
  end

end
