defmodule Exyaml.Loader do
  @on_load :init

  # --- *\n
  # ... *\n   ドキュメントの終わり
  # - すでに終わった後に空行は無視される
  # - 終わった後に ...\nは無視される
  # - 終わった後に ---\n は開始となる
  # - 終わった後に上記以外も開始となる
  # ---
  #
  @re_document_sep ~r/^---\s/
  @re_document_end ~r/^\.\.\.\s*\n/

  #
  # Yamerl初期化
  # ---
  #   デフォルトでtimestampを認識するように設定しておく
  #
  def init() do
    Application.ensure_loaded(:yamerl)
    :yamerl_app.set_param(:node_mods, [:yamerl_node_timestamp])
  end

  #
  # 単一のYAMLドキュメントをロードする
  # 複数ドキュメントの場合はエラーとなる
  #
  def load(device, source) do
    stream(device, source)
    |> Enum.take(2)  # 複数ドキュメントかどうかチェックするため最大2つ取り出す
    |> case do
         [] -> nil
         [data] -> data
         _ -> raise Exyaml.DocumentError, message: "found multiple document"
       end
  end

  #
  # 複数のYAMLドキュメントをロードして、ストリームデータとして返す
  #
  def load_all(device, source), do: stream(device, source)

  defp stream(device, source) do
    Stream.resource(
      fn -> stream_start(device, source) end,
      &stream_next/1,
      &stream_after/1
    )
    |> Enum.map(fn {:yamerl_doc, node} -> node_to_term(node) end)
  end

  defp stream_start(io_device, source), do: {io_device, :yamerl_constr.new(source, detailed_constr: true)}

  defp stream_next({_io_device, nil}), do: {:halt, :ok}
  defp stream_next({io_device, parser}) do
    {doc, parser} =
      IO.read(io_device, :line)
      |> do_stream(parser)
    {doc, {io_device, parser}}
  end

  defp stream_after(:ok), do: :ok
  defp stream_after(_), do: :error  # stream_next 処理中に例外が発生たい場合、この節が呼び出される
  #
  # 読み込んだ文字列データをパーサーに入力していく
  #
  defp do_stream({:error, reason}, _parser), do: raise IO.StreamError, reason: reason
  defp do_stream(:eof, parser), do: parser_next(parser, "", nil)
  defp do_stream(data, parser) do
    data = to_string(data)
    #
    # YAMLセパレータ毎に区切ってストリームの要素とする
    #
    cond do
      Regex.match?(@re_document_sep, data) ->
        {doc, parser} = parser_restart(parser)
        parser_next(parser, data, doc)
      Regex.match?(@re_document_end, data) ->
        parser_restart(parser, data)
      true ->
        parser_next(parser, data, [])
    end
  end

  #
  # 入力をパーサに与えて処理を進める
  #
  defp parser_next(parser, data, doc) do
    try do
      case :yamerl_constr.next_chunk(parser, data, is_nil(doc)) do
        #
        # doc が nil以外の場合、docと新しい状態のパーサを返す
        #
        {:continue, new_parser} -> {doc, new_parser}
        #
        # doc が nilの場合、最後の入力として、解析結果を返す
        #
        result_doc -> {result_doc, nil}
      end
    rescue
      FunctionClauseError ->
        #
        # 入力に不正な文字が含まれていた場合、
        # next_chunk()呼び出し内部で FunctionClauseError が発生する
        #
        [line: line, column: _col] = get_parser_pos(parser)
        raise Exyaml.ParseError, message: "Invalid character found", line: line
    catch
      {:yamerl_exception, [{:yamerl_parsing_error, :error, emesg, line, col, _err, :undefined, _extra}]} ->
        raise Exyaml.ParseError, message: emesg, line: line, col: col
      {:yamerl_exception, [{:yamerl_parsing_error, :error, emesg, _line, _col, _err, tok, _extra}]} ->
        [line: line, column: col] = :yamerl_constr.get_pres_details(tok)
        raise Exyaml.ParseError, message: emesg, line: line, col: col
    end
  end

  #
  # 解析処理を終了し、解析結果と新しいパーサを返す
  #
  defp parser_restart(parser, last_data \\ "") do
    {doc, nil} = parser_next(parser, last_data, nil)
    source = get_parser_source(parser)
    parser = :yamerl_constr.new(source, detailed_constr: true)
    {doc, parser}
  end

  defp get_parser_source(parser), do: elem(parser, 1)
  # defp get_parser_token(parser), do: elem(parser, 34)
  defp get_parser_pos(parser), do: [line: parser |> elem(9), column:  parser |> elem(10)]

  defp node_to_term({:yamerl_str, :yamerl_node_str, _tag, _pos, str}), do: to_string(str)
  defp node_to_term({:yamerl_int, :yamerl_node_int, _tag, _pos, int}), do: int
  defp node_to_term({:yamerl_float, :yamerl_node_float, _tag, _pos, float}), do: float
  defp node_to_term({:yamerl_null, :yamerl_node_null, _tag, _pos}), do: nil
  defp node_to_term({:yamerl_bool, :yamerl_node_bool, _tag, _pos, bool}), do: bool
  defp node_to_term({:yamerl_binary, :yamerl_node_binary, _tag, _pos, bin}), do: bin
  defp node_to_term({:yamerl_timestamp, :yamerl_node_timestamp, _tag, _pos, year, month, day, :undefined, :undefined, :undefined, _frac, _tz}) do
    {:ok, date} = Date.new(year, month, day)
    date
  end
  defp node_to_term({:yamerl_timestamp, :yamerl_node_timestamp, _tag, _pos, :undefined, :undefined, :undefined, hour, minute, second, _frac, _tz}) do
    {:ok, time} = Time.new(hour, minute, second)
    time
  end
  defp node_to_term({:yamerl_timestamp, :yamerl_node_timestamp, _tag, _pos, year, month, day, hour, minute, second, _frac, _tz}) do
    {:ok, date_time} =  NaiveDateTime.new(year, month, day, hour, minute, second)
    date_time
  end
  defp node_to_term({:yamerl_seq, :yamerl_node_seq, _tag, _pos, seq, _count}), do: Enum.map(seq, &node_to_term/1)
  defp node_to_term({:yamerl_map, :yamerl_node_map, _tag, _pos, map}) do
    for {key, val} <- map, into: %{} do
      {node_to_term(key), node_to_term(val)}
    end
  end
end
