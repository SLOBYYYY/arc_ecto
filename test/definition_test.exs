defmodule ArcTest.Ecto.Definition do
  use ExUnit.Case

  defmodule DummyDefinition do
    def url(_, :original, _), do: "fallback"
    def url(_, :signed, _), do: "fallback?a=1&b=2"
    def store({file, _}), do: {:ok, file}
    def delete(_), do: :ok
    defoverridable [delete: 1, url: 3]
    use Arc.Ecto.Definition
  end

  defp get_erlang_datetime() do
    {{2015, 1, 1}, {1, 1, 1}}
  end

  test "defines Definition.Type module" do
    assert {:file, []} == :code.is_loaded(DummyDefinition.Type)
    assert DummyDefinition.Type.type == Arc.Ecto.Type.type
  end

  test "falls back to pre-defined url" do
    assert DummyDefinition.url("test.png", :original, []) == "fallback"
  end

  test "url appends timestamp to url with no query parameters" do
    updated_at = NaiveDateTime.from_erl!(get_erlang_datetime())
    url = DummyDefinition.url({%{file_name: "test.png", updated_at: updated_at}, :scope}, :original, [])
    assert url == "fallback?v=63587293261"
  end

  test "url appends timestamp to url with query parameters" do
    updated_at = NaiveDateTime.from_erl!(get_erlang_datetime())
    url = DummyDefinition.url({%{file_name: "test.png", updated_at: updated_at}, :scope}, :signed, [])
    assert url == "fallback?a=1&b=2&v=63587293261"
  end

  test "url is unchanged if no timestamp is present" do
    url = DummyDefinition.url({%{file_name: "test.png", updated_at: nil}, :scope}, :original, [])
    assert url == "fallback"
  end

  test "milliseconds are ignored from url" do
    updated_at1 = NaiveDateTime.from_erl!(get_erlang_datetime())
    updated_at2 = NaiveDateTime.from_erl!(get_erlang_datetime(), {1000, 0})
    IO.inspect updated_at2
    updated_at3 = NaiveDateTime.from_erl!(get_erlang_datetime(), {999999, 0})
    IO.inspect updated_at3
    create_url = fn(updated_at) -> DummyDefinition.url({%{file_name: "test.png", updated_at: updated_at}, :scope}, :original, []) end
    url1 = create_url.(updated_at1)
    url2 = create_url.(updated_at2)
    url3 = create_url.(updated_at3)
    assert url1 == "fallback?v=63587293261"
    assert url2 == url1
    assert url3 == url1
  end
end
