require Logger
require FootprintSupport

defmodule Footprints do
  @moduledoc """
  This is the main driving module for the KiCad PCB footprint generator.
  """

  @doc """
    The entry point for the KiCad PCB footprint generator.

    ## Examples
        iex> Footprints.main([])
        :ok
  """
  def main(args) do
    {options, _unpargs, _invalid} = OptionParser.parse(
        args,
        switches: [ dir: :string, cfg: :string, help: :boolean ],
        aliases:  [ h: :help ],
        allow_nonexistent_atoms: true
    )

    if options[:help] do
        usage()
        exit(:shutdown)
    end

    process options
  end

  @doc """
    Prints the command line usage to the screen and exits.  This is expected to
    be called if the "--help" command line option is used.
  """
  def usage() do
    IO.puts "usage: footprints [-h] [-dir DIRECTORY] [-cfg DIRECTORY]"
    IO.puts ""
    IO.puts "Generate all the KiCad footprints specified in the config directory.  KiCad library"
    IO.puts "default values are specified in the cfg directory 'global_defaults.yml' YAML file."
    IO.puts "Values from the default file can be overridden via command line.  For example"
    IO.puts ""
    IO.puts "            ./footprints --soldermaskmargin=1.23"
    IO.puts ""
    IO.puts "will override the default value read from global_defaults.yml (nominally 0.05)"
    IO.puts "and instead use the value 1.23.  Any/all values can be overridden this way."
    IO.puts ""
    IO.puts "optional arguments:"
    IO.puts "  -h, --help      Show this help message and exit"
    IO.puts "  --verbose       Print progress data"
    IO.puts "  --dir DIRECTORY Output top-level directory into which KiCad libraries are written"
    IO.puts "  --cfg DIRECTORY Directory containing input YAML files specifying libraries/footprints to be made"
    IO.puts "  --PARAM VALUE   Sets a specific library/footprint value named 'PARAM' to the specified VALUE"
  end


  @doc """
    Processes all library/Yaml files to create the KiCad modules.  Input Yaml
    files are read from the directory specified with the 'cfg' command line
    option (defaults to './devices') with output modules written to the
    directory specified by the 'dir' option (defaults to ./DATA).
  """
  def process(options) do
    # Set input and output directories (defaults if not given on the command line)
    output_base_directory =
      if !options[:dir],
        do: "DATA",
        else: options[:dir]

    config_base_directory =
      if !options[:cfg],
        do: "devices",
        else: options[:dir]

    # Read the yaml file for default values.  This will make a keyword list
    # with the keyword "defaults" (others will be ignored) whose value is a
    # keyword list (key,value pairs) for the parameter values to use.  Note that
    # the returned map will have string keys.
    a = YamlElixir.read_from_file("#{config_base_directory}/global_defaults.yml")

    # Pull out the key-value pairs from the 'defaults' key of the read-in configuration
    # and map the keys to atoms.  The atoms will be used as the keys to the newly-created
    # defaults keyword list.  That is, we'll turn the a["defaults"] map with string
    # keys to a map with atoms as keys.
    defaults = for {key, val} <- a["defaults"], into: %{}, do: {String.to_atom(key), val}

    # Build the "overrides" keyword list.  The overrides list is a map of key-value
    # pairs that were passed in on the command line.  We'll hold these in the
    # overrides list and pass it to subsequent functions for overriding any settings.
    # This allows the command line parameters to have the highest precedence,
    # overriding the values from both the "global_defaults" and library-specific files.
    # Here 'options' is a list, we'll just turn it into a (possibly empty) map.
    overrides = for {key, val} <- options, into: %{}, do: {key, val}

    # Build each KiCad module.  Each device type has its own module with a build
    # function to write out the devices.  They'll all need to defaults and overrides
    # lists to specify default values.  Device-specific parameters will be loaded
    # from file in the  'config_base_directory' directory.
    Footprints.PTHHeader.build( 
      "PTH_Headers", 
      "PTH254Header_devices.yml", 
      defaults, 
      overrides, 
      output_base_directory, 
      config_base_directory
    )

    Footprints.PTHHeader.build(
      "PTH_Headers",
      "PTH127Header_devices.yml",
      defaults,
      overrides,
      output_base_directory,
      config_base_directory
    )

    Footprints.PTHHeaderRA.build(
      "PTH_Headers",
      "PTH254Header_devices.yml",
      defaults,
      overrides,
      output_base_directory,
      config_base_directory
    )

    Footprints.PTHHeaderRA.build(
      "PTH_Headers",
      "PTH127Header_devices.yml",
      defaults,
      overrides,
      output_base_directory,
      config_base_directory
    )

    Footprints.DF13Header.build(
      "PTH_Headers",
      "DF13Header_devices.yml",
      defaults,
      overrides,
      output_base_directory,
      config_base_directory
    )

    Footprints.DF13HeaderRA.build(
      "PTH_Headers",
      "DF13Header_devices.yml",
      defaults,
      overrides,
      output_base_directory,
      config_base_directory
    )

    Footprints.Combicon.build(
      "PTH_Headers",
      "combicon_devices.yml",
      defaults,
      overrides,
      output_base_directory,
      config_base_directory
    )

    Footprints.Drills.build(
      "Drills",
      "drills.yml",
      defaults,
      overrides,
      output_base_directory,
      config_base_directory
    )

    Footprints.Passives.build(
      "SMD_Passives",
      "rcl_devices.yml",
      defaults,
      overrides,
      output_base_directory,
      config_base_directory
    )

    Footprints.Diodes.build(
      "SMD_Passives",
      "smd_diode_devices.yml",
      defaults,
      overrides,
      output_base_directory,
      config_base_directory
    )

    Footprints.DIP.build(
      "DIP",
      "DIP_devices.yml",
      defaults,
      overrides,
      output_base_directory,
      config_base_directory
    )

    Footprints.SOIC.build(
      "SOP",
      "SOP_devices.yml",
      defaults,
      overrides,
      output_base_directory,
      config_base_directory
    )

    Footprints.QFP.build(
      "QFP",
      "QFP_devices.yml",
      defaults,
      overrides,
      output_base_directory,
      config_base_directory
    )

    Footprints.QFN.build(
      "QFN",
      "QFN_devices.yml",
      defaults,
      overrides,
      output_base_directory,
      config_base_directory
    )

    Footprints.SOT.build(
      "SOT",
      "SOT_devices.yml",
      defaults,
      overrides,
      output_base_directory,
      config_base_directory
    )

    Footprints.DPak.build(
      "TO",
      "TO_devices.yml",
      defaults,
      overrides,
      output_base_directory,
      config_base_directory
    )

    Footprints.ECap.build(
      "ECAP",
      "ecap_devices.yml",
      defaults,
      overrides,
      output_base_directory,
      config_base_directory
    )

    Footprints.DF13HeaderSMD.build(
      "SMD_Headers",
      "DF13SMDHeader_devices.yml",
      defaults,
      overrides,
      output_base_directory,
      config_base_directory
    )

    Footprints.DF13HeaderRASMD.build(
      "SMD_Headers",
      "DF13SMDHeader_devices.yml",
      defaults,
      overrides,
      output_base_directory,
      config_base_directory
    )

    Footprints.NanofitHeaderPTH.build(
      "PTH_Headers",
      "PTHnanofitHeader_devices.yml",
      defaults,
      overrides,
      output_base_directory,
      config_base_directory
    )

    :ok
  end
end
