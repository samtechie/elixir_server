defmodule Servy.ServicesSupervisor do
  use Supervisor

  def start_link do
    IO.puts "starting the services supervisor..."
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      Servy.PledgeServer,
      { Servy.SensorServer, 60}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

end
