defmodule ExyamlTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  @test_file_path "/tmp/test.yml"

  doctest Exyaml

  test "empty list" do
    assert Exyaml.dumps([]) == "[]\n"
  end

  test "empty map" do
    assert Exyaml.dumps(%{}) == "{}\n"
  end

  test "empty set" do
    assert Exyaml.dumps(MapSet.new()) == "!!set {}\n"
  end

  test "uri" do
    uri = "https://kenta_hattori@eightbirds.com/yamlib"
    assert Exyaml.dumps(URI.parse(uri)) == uri <> "\n"
  end

  test "nested list" do
    assert Exyaml.dumps([1, "foo", [true, 999]]) == "- 1
- foo
- - true
  - 999
"
  end

  test "nested map" do
    assert Exyaml.dumps(%{foo: 999, bar: %{"hoge" => "test"}}) == "bar:
  hoge: test
foo: 999
"
  end

  test "file dump" do
    :ok = Exyaml.dump(@test_file_path, "hello")
    {:ok, io} = File.open(@test_file_path)
    assert "hello\n" == IO.read(io, :all)
    on_exit (fn ->
      File.close(io)
      File.rm!(@test_file_path)
    end)
  end

  test "dump stdout" do
    assert capture_io(fn -> :ok = Exyaml.dump(1) end) == "1\n"
  end

  test "file dump_all" do
    :ok = Exyaml.dump_all(@test_file_path, ["hello", "world"])
    {:ok, io} = File.open(@test_file_path)
    assert "---\nhello\n---\nworld\n" == IO.read(io, :all)
    on_exit (fn ->
      File.close(io)
      File.rm!(@test_file_path)
    end)
  end

  test "dump_all stdout" do
    assert capture_io(fn -> :ok = Exyaml.dump_all([1, 2]) end) == "---\n1\n---\n2\n"
  end

  test "load from stdin" do
    assert capture_io("test", fn ->
      result = Exyaml.load()
      IO.puts("result: " <> result)
    end) == "result: test\n"
  end

  test "load from device" do
    {:ok, io} = File.open(@test_file_path, [:write])
    IO.write(io, "1")
    :ok = File.close(io)
    {:ok, io} = File.open(@test_file_path)
    assert 1 == Exyaml.load(io)
    on_exit (fn ->
      :ok = File.close(io)
      File.rm!(@test_file_path)
    end)
  end

  test "file load" do
    {:ok, io} = File.open(@test_file_path, [:write])
    IO.write(io, "1")
    :ok = File.close(io)
    assert 1 == Exyaml.load(@test_file_path)
    on_exit (fn ->
      File.rm!(@test_file_path)
    end)
  end

  test "load_all from stdin" do
    assert capture_io("test", fn ->
      [result] = Exyaml.load_all() |> Enum.to_list()
      IO.puts("result: " <> result)
    end) == "result: test\n"
  end

  test "load_all from device" do
    {:ok, io} = File.open(@test_file_path, [:write])
    IO.write(io, "Hello\n\world!\n")
    :ok = File.close(io)
    {:ok, io} = File.open(@test_file_path)
    assert ["Hello world!"] == Exyaml.load_all(io)
    on_exit (fn ->
      :ok = File.close(io)
      File.rm!(@test_file_path)
    end)
  end

  test "file load_all" do
    {:ok, io} = File.open(@test_file_path, [:write])
    IO.write(io, "Hello\nworld!\n")
    :ok = File.close(io)
    assert ["Hello world!"] == Exyaml.load_all(@test_file_path)
    on_exit (fn ->
      File.rm!(@test_file_path)
    end)
  end
end
