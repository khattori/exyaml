defmodule Exyaml do
  @moduledoc """
  Exyaml is YAML dumper/loader for Elixir.
  """

  alias Exyaml.Dumper
  alias Exyaml.Loader

  @version Mix.Project.config[:version]

  @doc ~S"""
  Get version.

  ## Examples

      iex> Exyaml.version()
      "0.1.0"

  """
  def version(), do: @version

  def load(device_or_path \\ :stdio)
  def load(:stdio), do: Loader.load(:stdio, {:file, "<stdin>"})
  def load(path) when is_binary(path), do: file_in_wrap(path, :load)
  def load(device), do: Loader.load(device, {:file, "<io>"})

  def load_all(dervice_or_path \\ :stdio)
  def load_all(:stdio), do: Loader.load_all(:stdio, {:file, "<stdin>"})
  def load_all(path) when is_binary(path), do: file_in_wrap(path, :load_all)
  def load_all(device), do: Loader.load_all(device, {:file, "<io>"})

  @doc ~S"""
  Load YAML data from string.

  ## Examples

      iex> Exyaml.loads("")
      nil

      iex> Exyaml.loads("null")
      nil

      iex> Exyaml.loads("true")
      true

      iex> Exyaml.loads("hello")
      "hello"

      iex> Exyaml.loads("-123")
      -123

      iex> Exyaml.loads("3.1415926")
      3.1415926

      iex> Exyaml.loads("12:34:56")
      ~T[12:34:56]

      iex> Exyaml.loads("2020-07-24")
      ~D[2020-07-24]

      iex> Exyaml.loads("2000-01-01 00:00:00")
      ~N[2000-01-01 00:00:00]

      iex> Exyaml.loads("!!binary AQIDBAU=")
      <<1, 2, 3, 4, 5>>

      iex> Exyaml.loads("foo: bar")
      %{"foo" => "bar"}

      iex> Exyaml.loads("- 1")
      [1]

      iex> Exyaml.loads("- 1\nfoo: bar")
      ** (Exyaml.ParseError) Invalid sequence: line 2, col 1

      iex> Exyaml.loads("foo: bar\n-")
      ** (Exyaml.ParseError) Expected sequence entry or mapping implicit key not found: line 2, col 1

      iex> Exyaml.loads("---\n---\n")
      ** (Exyaml.DocumentError) found multiple document

      iex> Exyaml.loads("invalid \f")
      ** (Exyaml.ParseError) Invalid character found: line 1

  """
  def loads(text) when is_binary(text), do: string_in_wrap(:load, text)

  @doc ~S"""
  Load multiple YAML document from string and return data as stream.

  ## Examples

      iex> Exyaml.loads_all("---\n---\n") |> Enum.to_list()
      [nil, nil]

      iex> Exyaml.loads_all("---\ntest\n...\n") |> Enum.to_list()
      ["test"]

  """
  def loads_all(text) when is_binary(text), do: string_in_wrap(:load_all, text)

  @doc ~S"""
  Dump data into device or file.
  """
  def dump(device_or_path \\ :stdio, data)
  def dump(path, data) when is_binary(path), do: file_out_wrap(path, :dump, data)
  def dump(device, data), do: Dumper.dump(device, data)

  @doc ~S"""
  Dump enumerable data into device or file as multiple documents.
  """
  def dump_all(device_or_path \\ :stdio, data)
  def dump_all(path, enumerable) when is_binary(path), do: file_out_wrap(path, :dump_all, enumerable)
  def dump_all(device, enumerable), do: Dumper.dump_all(device, enumerable)

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

      iex> Exyaml.dumps(MapSet.new([1, 2, 3]))
      "!!set\n? 1\n? 2\n? 3\n"

      iex> Stream.cycle(["test message" <> <<1,2,3,4,5>>]) |> Enum.take(10) |> Enum.join |> Exyaml.dumps
      "!!binary |\n  dGVzdCBtZXNzYWdlAQIDBAV0ZXN0IG1lc3NhZ2UBAgMEBXRlc3QgbWVzc2FnZQECAwQFdGVzdCBt\n  ZXNzYWdlAQIDBAV0ZXN0IG1lc3NhZ2UBAgMEBXRlc3QgbWVzc2FnZQECAwQFdGVzdCBtZXNzYWdl\n  AQIDBAV0ZXN0IG1lc3NhZ2UBAgMEBXRlc3QgbWVzc2FnZQECAwQFdGVzdCBtZXNzYWdlAQIDBAU=\n"

  """
  def dumps(data), do: string_out_wrap(:dump, data)

  @doc ~S"""
  Dump enumerable data into YAML formatted string as multiple documents.

  ## Examples

      iex> Exyaml.dumps_all([])
      ""

      iex> Exyaml.dumps_all(["hello"])
      "---\nhello\n"
  """
  def dumps_all(enumerable), do: string_out_wrap(:dump_all, enumerable)

  defp file_in_wrap(path, fun_name) do
    {:ok, io} = File.open(path)
    result = apply(Loader, fun_name, [io, {:file, Path.basename(path)}])
    :ok = File.close(io)
    result
  end

  defp file_out_wrap(path, fun_name, data) do
    {:ok, io} = File.open(path, [:write])
    apply(Dumper, fun_name, [io, data])
    :ok = File.close(io)
  end

  defp string_in_wrap(fun_name, text) do
    {:ok, io} = StringIO.open(text)
    result = apply(Loader, fun_name, [io, :string])
    {:ok, {"", ""}} = StringIO.close(io)
    result
  end

  defp string_out_wrap(fun_name, data) do
    {:ok, io} = StringIO.open("")
    apply(Dumper, fun_name, [io, data])
    {:ok, {"", result}} = StringIO.close(io)
    result
  end
end
