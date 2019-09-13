
defmodule Servy.Handler do
  @moduledoc "Handles HTTP requests"

  alias Servy.Conv
  alias Servy.BearController

  @pages_path Path.expand("../../pages",__DIR__)

  import Servy.Plugins, only: [rewrite_path: 1, log: 1, track: 1]
  import Servy.Parser, only: [parse: 1]

  @doc "Transforms request into response"
  def handle(request) do
    request
    |> parse
    |> rewrite_path
    #|> log
    |> route
    |> track
    |> format_response
  end

  def route(%Conv{ method: "GET", path: "/kaboom" } = conv) do
    raise "Kaboom!"
  end

  def route(%Conv{ method: "GET", path: "/hibernate/" <> time } = conv) do
    time |> String.to_integer |> :timer.sleep

    %{ conv | status: 200, resp_body: "Awake!" }
  end

  def route(%Conv{method: "GET", path: "/wildthings"} = conv) do
    %{conv | status: 200, resp_body: "Bears, Lions, Tigers"}
  end

  def route(%Conv{method: "GET", path: "/api/bears"} = conv) do
    Servy.Api.BearController.index(conv)
  end

  def route(%Conv{method: "GET", path: "/bears"} = conv) do
    BearController.index(conv)
  end

  def route(%Conv{method: "GET", path: "/bears/" <> id} = conv) do
    params = Map.put(conv.params, "id", id)

    BearController.show(conv, params)
  end
  #name=Baloo&type=Brown
  def route(%Conv{method: "POST", path: "/bears"} = conv) do
    BearController.create(conv,conv.params)
  end


  def route(%Conv{method: "GET", path: "/about"} = conv) do
      @pages_path
      |> Path.join("about.html")
      |> File.read
      |> handle_file(conv)
  end

  def handle_file({:ok,content},conv)do
    %{conv | status: 200, resp_body: content}
  end

  def handle_file({:error, :enoent},conv) do
     %{conv | status: 404, resp_body: "File not found"}
  end
  def handle_file({:error, reason}, conv) do
    %{conv | status: 500, resp_body: "File error #{reason}"}
  end

  def route(%Conv{method: "GET", path: "/bears/new"} = conv) do
    file =
      Path.expand("../../pages", __DIR__)
      |> Path.join( "form.html")

    case File.read(file) do
      {:ok, content} ->
        %{ conv | status: 200, resp_body: content }

      {:error, :enoent} ->
        %{ conv | status: 404, resp_body: "File not found!"}

      {:error, reason } ->
        %{ conv | status: 500, resp_body: "File error: #{reason}"}
  end
end

  # def route(%{method: "GET", path: "/about"} = conv) do
  #   file =
  #     Path.expand("../../pages",__DIR__)
  #     |> Path.join("about.html")

  #   case File.read(file) do
  #     {:ok, content} ->
  #       %{conv | status: 200, resp_body: content}

  #     {:error, :enoent} ->
  #       %{conv | status: 404, resp_body: "File not found"}

  #     {:error, reason} ->
  #       %{conv | status: 500, resp_body: "File error #{reason}"}
  #   end
  # end

  def route(%Conv{path: path} = conv) do
    %{conv | status: 404, resp_body: "No #{path} here!"}
  end

  def format_response(%Conv{} = conv) do
    """
    HTTP/1.1 #{Conv.full_status(conv)}\r
    Content-Type: #{conv.resp_content_type}\r
    Content-Length: #{String.length(conv.resp_body)}\r
    \r
    #{conv.resp_body}
    """
  end
end

