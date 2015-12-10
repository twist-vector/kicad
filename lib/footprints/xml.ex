defmodule Footprints.Xml do

  # By default all values will be float, keywords will be atoms (a dictionary
  # of floats).  Use the "converter" as_int to get the value as an integer.  No
  # provisions for storing strings in the dictionary at this point.
  def read_defaults(old, filename) do
    {:ok, data} = File.read filename
    doc = Exml.parse data
    vals  = Exml.get doc, "//param"
    names = Exml.get doc, "//param/@name"

    pairs = Enum.map(vals, fn val -> elem(Float.parse(val),0) end)
            |> Enum.zip(names)
            |> Enum.map(fn {v,k} -> {String.to_atom(k),v} end)
    Map.merge old, Enum.into(pairs, %{})
  end

  def as_int(hash, a), do: String.to_integer(hash[a])

end
