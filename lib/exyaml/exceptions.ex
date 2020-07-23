defmodule Exyaml.ParseError do
  defexception message: "parse error", line: nil, col: nil
  def message(%{line: nil} = me), do: "#{me.message}"
  def message(%{col: nil} = me), do: "#{me.message}: line #{me.line}"
  def message(me), do: "#{me.message}: line #{me.line}, col #{me.col}"
end


defmodule Exyaml.DocumentError do
  defexception message: "document error"
  def message(me), do: me.message
end
