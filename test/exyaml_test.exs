defmodule ExyamlTest do
  use ExUnit.Case
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
end
