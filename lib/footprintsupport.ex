require Logger

defmodule FootprintSupport do


  @doc """
    Override default parameters for a library (set of modules) and adds
    device specific values.  The override based on command line parameters
    (passed in via `overrides` variable)
  """
  def make_params(paramFile, baseDefaults, overrides) do
    temp = YamlElixir.read_from_file(paramFile)
    p = Enum.map(temp["defaults"], fn({k,v})-> Map.put(%{}, String.to_atom(k), v) end)
        |> Enum.reduce(fn(data, acc)-> Map.merge(data,acc) end)
    p2 = Map.merge baseDefaults, p
    params = Map.merge p2, overrides
    params
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


end
