defmodule Exyaml do
  @moduledoc """
  Exyaml is YAML dumper/loader for Elixir.
  """

  alias Exyaml.Dumper
  alias Exyaml.Loader


  def load(device \\ :stdio), do: Loader.load(device)

  @doc """
  Load YAML data.

  ## Examples

      iex> Exyaml.loads("")
      nil

      iex> Exyaml.loads("hello")
      "hello"

      iex> Exyaml.loads("foo: bar")
      %{"foo" => "bar"}
  """
  def loads(text) when is_binary(text) do
    {:ok, sio} = StringIO.open(text)
    load(sio)
  end

  @doc """
  Dump data into YAML
  """
  def dump(device \\ :stdio, data), do: Dumper.dump(device, data)

  @doc ~S"""
  Dump data into YAML formatted string.

  ## Examples

      iex> Exyaml.dumps(nil)
      "\n"

      iex> Exyaml.dumps("")
      "''\n"

      iex> Exyaml.dumps(1.23)
      "1.23\n"

      iex> Exyaml.dumps(0)
      "0\n"

      iex> Exyaml.dumps(:this_is_atom)
      "this_is_atom\n"

      iex> Exyaml.dumps(~D[2020-07-06])
      "2020-07-06\n"

      iex> Exyaml.dumps(~U[2020-12-31 23:59:59Z])
      "2020-12-31 23:59:59Z\n"

      iex> Exyaml.dumps(~N[2021-01-01 00:00:00])
      "2021-01-01 00:00:00\n"

      iex> Exyaml.dumps(~T[12:34:56])
      "12:34:56\n"

      iex> Exyaml.dumps("foo\nbar\nbaz\n")
      "|\n  foo\n  bar\n  baz\n"

      iex> Exyaml.dumps(<<1, 2, 3, 4>>)
      "!!binary AQIDBA==\n"

      iex> Exyaml.dumps(%{"foo" => "bar"})
      "foo: bar\n"

      iex> Exyaml.dumps([1, 2, "foo", true])
      "- 1\n- 2\n- foo\n- true\n"

  """
  def dumps(data) do
    {:ok, sio} = StringIO.open("")
    dump(sio, data)
    {:ok, {_, result}} = StringIO.close(sio)
    result
  end

  def dump_all(device \\ :stdio, enumerable), do: Dumper.dump_all(device, enumerable)
  def load_all(device \\ :stdio), do: nil # Enumerable を返す
end
