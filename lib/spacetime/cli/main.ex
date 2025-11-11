defmodule Spacetime.CLI.Main do
  @version "0.1.0"

  def setup do
    [
      name: "spacetime",
      description: "A version control system where code obeys the laws of physics",
      version: @version,
      author: "Arun George Saji",
      about: "Manage your code with cosmic principles",
      allow_unknown_args: false,
      parse_double_dash: true,
      subcommands: [
        init: [
          name: "init",
          about: "Initialize a new Spacetime repository"
        ],
        status: [
          name: "status",
          about: "Show repository status"
        ]
      ]
    ]
  end

  def run(args) do
    optimus = Optimus.new!(setup())

    case Optimus.parse(optimus, args) do
      {:ok, %{args: []}, _} ->
        IO.puts(Optimus.help(optimus))

      {:ok, %{args: ["init"]}, _} ->
        init_repository()

      {:ok, %{args: ["status"]}, _} ->
        show_status()

      {:error, errors} ->
        IO.puts("Error: #{Enum.join(errors, ", ")}")
        System.halt(1)

      _ ->
        IO.puts(Optimus.help(optimus))
        System.halt(1)
    end
  end

  def main(args), do: run(args)

  defp init_repository do
    IO.puts("Initializing new Spacetime repository...")

    File.mkdir_p!(".spacetime/objects")
    File.mkdir_p!(".spacetime/refs/heads")

    config = %{
      version: 1,
      physics: %{
        redshift_enabled: true,
        gravity_enabled: true
      }
    }

    File.write!(".spacetime/config", Jason.encode!(config, pretty: true))
    IO.puts("Spacetime repository initialized!")
  end

  defp show_status do
    IO.puts("Scanning spacetime continuum...")

    if File.exists?(".spacetime/config") do
      IO.puts("Repository: Spacetime-enabled")
      IO.puts("Physics: Redshift and Gravity primed")
    else
      IO.puts("Not a spacetime repository")
      IO.puts("Run 'spacetime init' to begin")
    end
  end
end
