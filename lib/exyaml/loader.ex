defmodule Exyaml.Loader do
  def load(device) do
    IO.stream(device, :line)
    |> Enum.join
    |> :yamerl_constr.string
    |> List.first
  end
end
