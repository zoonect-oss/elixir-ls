defmodule ElixirLS.LanguageServer.Sequencer do
  use GenServer
  require Logger

  @timeout :infinity

  # Client APIs

  def start_link(name \\ nil) do
    Logger.info("Called ElixirLS.LanguageServer.Sequencer.start_link")
    GenServer.start_link(__MODULE__, :ok, name: name || __MODULE__)
  end

  def reload_project(server \\ __MODULE__) do
    Logger.info("Called ElixirLS.LanguageServer.Sequencer.reload_project")
    GenServer.call(server, :reload_project, @timeout)
  end

  def experimental_formatter_for(server \\ __MODULE__, uri_or_path) do
    Logger.info("Called ElixirLS.LanguageServer.Sequencer.experimental_formatter_for(uri_or_path)")
    GenServer.call(server, {:experimental_formatter_for, uri_or_path}, @timeout)
  end

  def formatter_for(server \\ __MODULE__, uri) do
    Logger.info("Called ElixirLS.LanguageServer.Sequencer.formatter_for(uri)")
    GenServer.call(server, {:formatter_for, uri}, @timeout)
  end

  # Callbacks

  @impl GenServer
  def init(:ok) do
    {:ok, nil}
  end

  @impl GenServer
  def handle_call(:reload_project, _from, state) do
    Logger.info("Called ElixirLS.LanguageServer.Sequencer.handle_call(reload_project)")
    {:reply, ElixirLS.LanguageServer.Build.reload_project(), state}
  rescue
    error ->
      Logger.warn("Rescue in Sequencer.handle_call(reload_project) from error: #{inspect(error)}!")
      {:reply, {:error, []}, state}
  end

  @impl GenServer
  def handle_call({:experimental_formatter_for, uri_or_path}, _from, state) do
    Logger.info("Called ElixirLS.LanguageServer.Sequencer.handle_call(experimental_formatter_for, uri_or_path)")
    {:reply, ElixirLS.LanguageServer.Experimental.CodeMod.Format.formatter_for(uri_or_path), state}
  end

  @impl GenServer
  def handle_call({:formatter_for, uri}, _from, state) do
    Logger.info("Called ElixirLS.LanguageServer.Sequencer.handle_call(formatter_for, uri)")
    {:reply, ElixirLS.LanguageServer.SourceFile.formatter_for(uri), state}
  end
end
