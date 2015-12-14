
defmodule Footprints do

  def main(args) do
    args
    |> parse_args
    |> process
  end


  def check_ret( {_,""} ), do: true
  def check_ret( :error ), do: false
  def check_ret( _ ), do: false

  def to_native(v) do
    cond do
      check_ret( Integer.parse(v) ) -> # integer
        {v,_rest} = Integer.parse(v)
        v
      check_ret( Float.parse(v) )   -> # float
        {v,_rest} = Float.parse(v)
        v
      String.upcase(v) == "TRUE"    -> # boolean
        true
      String.upcase(v) == "FALSE"   -> # boolean
        false
      true                          -> v
    end
  end


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


    overrides = if options != [], do:
                   Enum.map(options, fn({k,v})-> Map.put(%{}, k, to_native(v)) end)
                   |> Enum.reduce(fn(data, acc)-> Map.merge(data,acc) end),
                 else: %{}

    # Footprints.PTH254Header.build(defaults, overrides, output_base_directory, config_base_directory)
    # Footprints.PTH254HeaderRA.build(defaults, overrides, output_base_directory, config_base_directory)
    # Footprints.PTH127Header.build(defaults, overrides, output_base_directory, config_base_directory)
    # Footprints.PTH127HeaderRA.build(defaults, overrides, output_base_directory, config_base_directory)
    # Footprints.Passives.build(defaults, overrides, output_base_directory, config_base_directory)
    # Footprints.Diodes.build(defaults, overrides, output_base_directory, config_base_directory)
    # Footprints.SOIC.build(defaults, overrides, output_base_directory, config_base_directory)
    # Footprints.DF13Header.build(defaults, overrides, output_base_directory, config_base_directory)
    # Footprints.DF13HeaderRA.build(defaults, overrides, output_base_directory, config_base_directory)
    # Footprints.QFP.build(defaults, overrides, output_base_directory, config_base_directory)
    # Footprints.QFN.build(defaults, overrides, output_base_directory, config_base_directory)
    Footprints.Drills.build(defaults, overrides, output_base_directory, config_base_directory)
  end



  defp parse_args(args) do
    {options, _, _} = OptionParser.parse(args,
      switches: [dir: :string, cfg: :string]
    )
    options
  end

end
