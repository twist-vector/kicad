require Logger
require FootprintSupport

defmodule Footprints do
  @moduledoc """
  This is the main driving module for the KiCad PCB footprint generator.
  """

  @doc """
    `Footprints.main/1` is the entry point for the KiCad PCB footprint generator.

    ## Examples
        iex> Footprints.main([])
        Input config directory:   devices
        Output library directory: DATA
        :ok
  """
  def main(args) do
    args
    |> parse_args
    |> process
  end


  defp parse_args(args) do
    {options, _, _} = OptionParser.parse(args,
      switches: [dir: :string, cfg: :string]
    )
    options
  end


  @doc """
    Processes all library/Yaml files to create the KiCad modules.  Input Yaml
    files are read from the directory specified with the 'cfg' command line
    option (defaults to './devices') with output modules written to the
    directory specified by the 'dir' option (defaults to ./DATA).
  """
  def process(options) do
    # Set input and output directories (defaults if not given on the command line)
    output_base_directory = if !options[:dir], do: "DATA",
                            else:                  options[:dir]
    config_base_directory = if !options[:cfg], do: "devices",
                            else:                  options[:dir]

    # # A bit of text to show where things are coming from and where they're going.
    # IO.puts "Input config directory:   #{config_base_directory}"
    # IO.puts "Output library directory: #{output_base_directory}"

    # Read in default values from the 'global_config.yml' file.

    # Read the yaml file for default values.  This will bake a keyword list
    # with the keyword "defaults" (others will be ignored) whos value is a
    # keyword list (key,value pairs) for the parameter values to use.
    a = YamlElixir.read_from_file("#{config_base_directory}/global_defaults.yml")

    # Pull out the key-value pairs from the 'defaults' key and map the keys to
    # atoms.  The atoms will be used as the keys to the newly-created defaults
    # keyword list.
    defaults = Enum.map(a["defaults"], fn({k,v})-> Map.put(%{}, String.to_atom(k), v) end)
               |> Enum.reduce(fn(data, acc)-> Map.merge(data,acc) end)

    # Build the "overrides" keyword list.  The overrides list is a set of key-value
    # pairs that were passed in on the command line.  We'll hold these in the
    # overrides list and pass it to subsequent functions for overriding any settings.
    # This allows the command line parameters to have the highest precedence,
    # overriding the values from both the "global_defaults" and library-specific files.
    overrides = if options != [], do:
                   Enum.map(options, fn({k,v})-> Map.put(%{}, k, FootprintSupport.to_native(v)) end)
                   |> Enum.reduce(fn(data, acc)-> Map.merge(data,acc) end),
                 else: %{}


    # Build each KiCad module.  Each device type has its own module with a build
    # function to write out the devices.  They'll all need to defaults and overrides
    # lists to specify default values.  Device-specific parameters will be loaded
    # from file in the  'config_base_directory' directory.
    Footprints.PTHHeader.build("PTH_Headers", "PTH254Header_devices.yml", defaults, overrides, output_base_directory, config_base_directory)
    Footprints.PTHHeader.build("PTH_Headers", "PTH127Header_devices.yml", defaults, overrides, output_base_directory, config_base_directory)
    Footprints.PTHHeaderRA.build("PTH_Headers", "PTH254Header_devices.yml", defaults, overrides, output_base_directory, config_base_directory)
    Footprints.PTHHeaderRA.build("PTH_Headers", "PTH127Header_devices.yml", defaults, overrides, output_base_directory, config_base_directory)
    Footprints.DF13Header.build("PTH_Headers", "DF13Header_devices.yml", defaults, overrides, output_base_directory, config_base_directory)
    Footprints.DF13HeaderRA.build("PTH_Headers", "DF13Header_devices.yml", defaults, overrides, output_base_directory, config_base_directory)
    Footprints.Combicon.build("PTH_Headers", "combicon_devices.yml", defaults, overrides, output_base_directory, config_base_directory)
    Footprints.Drills.build("Drills", "drills.yml", defaults, overrides, output_base_directory, config_base_directory)
    Footprints.Passives.build("SMD_Passives", "rcl_devices.yml", defaults, overrides, output_base_directory, config_base_directory)
    Footprints.Diodes.build("SMD_Passives", "smd_diode_devices.yml", defaults, overrides, output_base_directory, config_base_directory)
    Footprints.DIP.build("DIP", "DIP_devices.yml", defaults, overrides, output_base_directory, config_base_directory)
    Footprints.SOIC.build("SOP", "SOP_devices.yml", defaults, overrides, output_base_directory, config_base_directory)
    Footprints.QFP.build("QFP", "QFP_devices.yml", defaults, overrides, output_base_directory, config_base_directory)
    Footprints.QFN.build("QFN", "QFN_devices.yml", defaults, overrides, output_base_directory, config_base_directory)
    Footprints.SOT.build("SOT", "SOT_devices.yml", defaults, overrides, output_base_directory, config_base_directory)
    Footprints.DPak.build("TO", "TO_devices.yml", defaults, overrides, output_base_directory, config_base_directory)
    Footprints.ECap.build("ECAP", "ecap_devices.yml", defaults, overrides, output_base_directory, config_base_directory)
    Footprints.DF13HeaderSMD.build("SMD_Headers", "DF13SMDHeader_devices.yml", defaults, overrides, output_base_directory, config_base_directory)
    Footprints.DF13HeaderRASMD.build("SMD_Headers", "DF13SMDHeader_devices.yml", defaults, overrides, output_base_directory, config_base_directory)
    Footprints.NanofitHeaderPTH.build("PTH_Headers", "PTHnanofitHeader_devices.yml", defaults, overrides, output_base_directory, config_base_directory)
  end




end
