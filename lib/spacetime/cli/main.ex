defmodule Spacetime.CLI.Main do
  @version "1.0"
  
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
          about: "Initialize a new Spacetime repository",
          args: []
        ],
        status: [
          name: "status",
          about: "Show repository status",
          args: []
        ]
      ]
    ]
  end
  
  def run(args) do
    optimus = Optimus.new!(setup())
    
    case Optimus.parse!(optimus, args) do
      {[:init], _parsed} ->
        init_repository()
        
      {[:status], _parsed} ->
        show_status()
        
      {[], _parsed} ->
        IO.puts(Optimus.help(optimus))
        
      _ ->
        IO.puts("Unknown command")
        System.halt(1)
    end
  rescue
    e in Optimus.ParseError ->
      IO.puts("Error: #{e.message}")
      System.halt(1)
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
      object_count = count_objects()
      IO.puts("Objects in storage: #{object_count}")
    else
      IO.puts("Not a spacetime repository")
      IO.puts("Run 'spacetime init' to begin")
    end
  end
  
  defp count_objects do
    objects_dir = ".spacetime/objects"
    
    if File.exists?(objects_dir) do
      objects_dir
      |> File.ls!()
      |> Enum.filter(fn dir -> String.length(dir) == 2 end)
      |> Enum.flat_map(fn dir ->
        Path.join([objects_dir, dir])
        |> File.ls!()
      end)
      |> Enum.count()
    else
      0
    end
  end
end
