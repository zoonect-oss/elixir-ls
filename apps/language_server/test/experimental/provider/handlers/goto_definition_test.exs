defmodule ElixirLS.Experimental.Provider.Handlers.GotoDefinitionTest do
  alias LSP.Requests.GotoDefinition
  alias LSP.Responses
  alias ElixirLS.LanguageServer.Experimental.Provider.Env
  alias ElixirLS.LanguageServer.Experimental.Provider.Handlers
  alias ElixirLS.LanguageServer.Experimental.SourceFile
  alias ElixirLS.LanguageServer.Experimental.SourceFile.Conversions
  alias ElixirLS.LanguageServer.Fixtures.LspProtocol
  alias ElixirLS.LanguageServer.Test.FixtureHelpers

  import LspProtocol
  import ElixirLS.Test.TextLoc, only: [annotate_assert: 4]
  use ExUnit.Case, async: true

  setup do
    {:ok, _} = start_supervised(SourceFile.Store)
    :ok
  end

  def request(file_path, line, char) do
    uri = Conversions.ensure_uri(file_path)

    params = [
      text_document: [uri: uri],
      position: [line: line, character: char]
    ]

    with {:ok, contents} <- File.read(file_path),
         :ok <- SourceFile.Store.open(uri, contents, 1),
         {:ok, req} <- build(GotoDefinition, params) do
      GotoDefinition.to_elixir(req)
    end
  end

  def handle(request) do
    Handlers.GotoDefinition.handle(request, Env.new())
  end

  def with_referenced_file(_) do
    path = FixtureHelpers.get_path("references_referenced.ex")
    uri = Conversions.ensure_uri(path)
    {:ok, file_uri: uri, file_path: path}
  end

  describe "when a file contains references" do
    setup [:with_referenced_file]

    test "find definition remote function call", %{file_uri: uri} do
      file_path = FixtureHelpers.get_path("references_remote.ex")
      {line, char} = {4, 28}

      {:ok, request} = request(file_path, line, char)

      annotate_assert(file_path, line, char, """
          ReferencesReferenced.referenced_fun()
                                  ^
      """)

      {:reply, %Responses.GotoDefinition{result: definition}} = handle(request)

      assert definition.uri == uri
      assert definition.range.start.line == 1
      assert definition.range.start.character == 6
      assert definition.range.end.line == 1
      assert definition.range.end.character == 6
    end

    test "find definition remote macro call", %{file_uri: uri} do
      file_path = FixtureHelpers.get_path("references_remote.ex")
      {line, char} = {8, 28}

      {:ok, request} = request(file_path, line, char)

      annotate_assert(file_path, line, char, """
          ReferencesReferenced.referenced_macro a do
                                  ^
      """)

      {:reply, %Responses.GotoDefinition{result: definition}} = handle(request)

      assert definition.uri == uri
      assert definition.range.start.line == 8
      assert definition.range.start.character == 11
      assert definition.range.end.line == 8
      assert definition.range.end.character == 11
    end

    test "find definition imported function call", %{file_uri: uri} do
      file_path = FixtureHelpers.get_path("references_imported.ex")
      {line, char} = {4, 5}

      {:ok, request} = request(file_path, line, char)

      annotate_assert(file_path, line, char, """
          referenced_fun()
           ^
      """)

      {:reply, %Responses.GotoDefinition{result: definition}} = handle(request)

      assert definition.uri == uri
      assert definition.range.start.line == 1
      assert definition.range.start.character == 6
      assert definition.range.end.line == 1
      assert definition.range.end.character == 6
    end

    test "find definition imported macro call", %{file_uri: uri} do
      file_path = FixtureHelpers.get_path("references_imported.ex")
      {line, char} = {8, 5}

      {:ok, request} = request(file_path, line, char)

      annotate_assert(file_path, line, char, """
          referenced_macro a do
           ^
      """)

      {:reply, %Responses.GotoDefinition{result: definition}} = handle(request)

      assert definition.uri == uri
      assert definition.range.start.line == 8
      assert definition.range.start.character == 11
      assert definition.range.end.line == 8
      assert definition.range.end.character == 11
    end

    test "find definition local function call", %{file_uri: uri} do
      file_path = FixtureHelpers.get_path("references_referenced.ex")
      {line, char} = {15, 5}

      {:ok, request} = request(file_path, line, char)

      annotate_assert(file_path, line, char, """
          referenced_fun()
           ^
      """)

      {:reply, %Responses.GotoDefinition{result: definition}} = handle(request)

      assert definition.uri == uri
      assert definition.range.start.line == 1
      assert definition.range.start.character == 6
      assert definition.range.end.line == 1
      assert definition.range.end.character == 6
    end

    test "find definition local macro call", %{file_uri: uri} do
      file_path = FixtureHelpers.get_path("references_referenced.ex")
      {line, char} = {19, 5}

      {:ok, request} = request(file_path, line, char)

      annotate_assert(file_path, line, char, """
          referenced_macro a do
           ^
      """)

      {:reply, %Responses.GotoDefinition{result: definition}} = handle(request)

      assert definition.uri == uri
      assert definition.range.start.line == 8
      assert definition.range.start.character == 11
      assert definition.range.end.line == 8
      assert definition.range.end.character == 11
    end

    test "find definition variable", %{file_uri: uri} do
      file_path = FixtureHelpers.get_path("references_referenced.ex")
      {line, char} = {4, 13}

      {:ok, request} = request(file_path, line, char)

      annotate_assert(file_path, line, char, """
          IO.puts(referenced_variable + 1)
                   ^
      """)

      {:reply, %Responses.GotoDefinition{result: definition}} = handle(request)

      assert definition.uri == uri
      assert definition.range.start.line == 2
      assert definition.range.start.character == 4
      assert definition.range.end.line == 2
      assert definition.range.end.character == 4
    end

    test "find definition attribute", %{file_uri: uri} do
      file_path = FixtureHelpers.get_path("references_referenced.ex")
      {line, char} = {27, 5}

      {:ok, request} = request(file_path, line, char)

      annotate_assert(file_path, line, char, """
          @referenced_attribute
           ^
      """)

      {:reply, %Responses.GotoDefinition{result: definition}} = handle(request)

      assert definition.uri == uri
      assert definition.range.start.line == 24
      assert definition.range.start.character == 2
      assert definition.range.end.line == 24
      assert definition.range.end.character == 2
    end
  end
end
