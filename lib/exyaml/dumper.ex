defmodule Exyaml.Dumper do
  @moduledoc ~S"""
  YAML emitter implementation
  """

  @cr "\r"
  @nl "\n"
  @sp " "
  @indent 2
  @wrap 76
  @yaml_sep "---"
  @yaml_seq "-"
  @yaml_key "?"
  @yaml_val ":"
  @yaml_txt "|"
  @yaml_txt_no_last_nl "|-"
  @yaml_tag_set "!!set"
  @yaml_tag_omap "!!omap"
  @yaml_tag_bin "!!binary"


  def dump(device, data) do
    IO.puts(device, do_dump(data, 0))
  end

  # StreamやEnumerable
  def dump_all(device, enumerable) do
    for data <- enumerable do
      IO.puts(device, @yaml_sep)
      dump(device, data)
    end
    :ok
  end

  defp do_dump(nil, _n), do: ""
  defp do_dump(data, _n) when is_atom(data), do: Atom.to_string(data)
  defp do_dump(data, _n) when is_integer(data), do: Integer.to_string(data)
  defp do_dump(data, _n) when is_float(data), do: Float.to_string(data)
  defp do_dump(%Date{} = data, _n), do: Date.to_string(data)
  defp do_dump(%DateTime{} = data, _n), do: DateTime.to_string(data)
  defp do_dump(%NaiveDateTime{} = data, _n), do: NaiveDateTime.to_string(data)
  defp do_dump(%Time{} = data, _n), do: Time.to_string(data)
  defp do_dump(%URI{} = data, _n), do: URI.to_string(data)
  #
  # リスト
  #
  defp do_dump([], _n), do: "[]"
  defp do_dump([_fst | _rest] = list, n) do
    if Keyword.keyword? list do
      [@yaml_tag_omap | Enum.map(list, fn {key, val} -> [@yaml_seq, @sp, dump_key(key, n + 1), dump_val(val, n + 1)] end)]
    else
      Enum.map(list, fn val -> [@yaml_seq, @sp, do_dump(val, n + 1)] end)
    end
    |> Enum.intersperse([@nl, indent(n)])
  end
  #
  # セット
  #
  defp do_dump(%MapSet{map: map}, _n) when map_size(map) == 0, do: [@yaml_tag_set, @sp, "{}"]
  defp do_dump(%MapSet{} = set, n) do
    [@yaml_tag_set | Enum.map(set, fn val -> [@yaml_key, @sp, do_dump(val, n + 1)] end)]
    |> Enum.intersperse([@nl, indent(n)])
  end
  #
  # 辞書
  #
  defp do_dump(%{} = dict, _n) when dict == %{}, do: "{}"
  defp do_dump(%{} = dict, n) do
    Enum.map(dict, fn {key, val} -> [dump_key(key, n + 1), dump_val(val, n + 1)] end)
    |> Enum.intersperse([@nl, indent(n)])
  end
  #
  # 文字列だがそれ以外の型として解釈されそうな場合は、quoteして出力する
  #
  defp do_dump(data, 0) when is_binary(data), do: do_dump(data, 1)  # indentが0（トップレベル）の場合はインデント量を1にする
  defp do_dump(data, n) when is_binary(data) do
    if printable? data do
      case String.split(data, [@nl, @cr<>@nl]) do
        [""] -> "''"
        [line] -> line
        [line | rest] ->
          #
          # 複数行の文字列
          #
          # 最後に改行がコードがある場合、最後の空文字要素を取り除く
          #
          if List.last(rest) == "" do
            [
              @yaml_txt, @nl,
              indent(n), line, @nl |
              List.pop_at(rest, -1)
              |> elem(1)
              |> Enum.map(fn l -> [indent(n), l] end)
              |> Enum.intersperse(@nl)
            ]
          else
            [
              @yaml_txt_no_last_nl, @nl,
              indent(n), line, @nl |
              Enum.map(rest, fn l -> [indent(n), l] end)
              |> Enum.intersperse(@nl)
            ]
          end
      end
    else
      case Base.encode64(data) |> wrap(n) do
        string when is_binary(string) -> "#{@yaml_tag_bin} #{string}"
        list -> [@yaml_tag_bin, @sp, @yaml_txt, @nl | list]
      end
    end
  end

  defp dump_key(key, n) do
    case do_dump(key, n) do
      list when is_list(list) -> [@yaml_key, @sp | list]
      string when is_binary(string) -> string
    end
  end

  defp dump_val(val, n) do
    case do_dump(val, n) do
      list when is_list(list) -> [@yaml_val, @nl, indent(n) | list]
      string when is_binary(string) -> [@yaml_val, @sp, string]
    end
  end

  defp indent(n), do: List.duplicate(@sp, n * @indent)

  @doc """
  Checks if a string contains only YAML printable characters.

  c-printable ::= #x9 | #xA | #xD | [#x20-#x7E]         /* 8 bit */
               | #x85 | [#xA0-#xD7FF] | [#xE000-#xFFFD] /* 16 bit */
               | [#x10000-#x10FFFF]                     /* 32 bit */

  ## Examples

      iex> Exyaml.Dumper.printable?("abc")
      true

      iex> Exyaml.Dumper.printable?("テスト")
      true

      iex> Exyaml.Dumper.printable?("abc" <> <<0>>)
      false

  """
  def printable?(string) when is_binary(string) do
    not String.contains?(string, ["\v", "\b", "\f", "\e", "\d", "\a"]) and String.printable?(string)
  end

  defp wrap("", _n), do: []
  defp wrap(string, n) do
    case String.split_at(string, @wrap) do
      {line, ""} -> line
      {line, rest} ->
        [
          indent(n), line, @nl |
          case wrap(rest, n) do
            string when is_binary(string) -> [indent(n), string]
            list -> list
          end
        ]
    end
  end
end
