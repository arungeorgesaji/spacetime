defmodule Spacetime.CLI.Commands.RedshiftStatus do
  def run do
    IO.puts "Scanning for redshift in spacetime continuum..."
    
    if not File.exists?(".spacetime/config") do
      IO.puts "Not a spacetime repository"
      IO.puts "Run 'spacetime init' to begin"
    end
    
    # Have to actually implement logic to check with the commit history instead of just current files 

    files = find_code_files()
    
    if Enum.empty?(files) do
      IO.puts "No code files found to analyze"
    else
      IO.puts "\nRedshift Analysis:"
      IO.puts "=" <> String.duplicate("=", 50)
      
      files
      |> Enum.map(fn file ->
        redshift = Spacetime.Physics.Redshift.calculate_redshift(file)
        description = Spacetime.Physics.Redshift.describe_redshift(redshift)
        {file, redshift, description}
      end)
      |> Enum.sort_by(fn {_, redshift, _} -> -redshift end)
      |> Enum.each(fn {file, redshift, description} ->
        percentage = Float.round(redshift * 100, 1)
        bars = String.duplicate("█", round(redshift * 10))
        spaces = String.duplicate(" ", 10 - round(redshift * 10))
        progress_bar = "[#{bars}#{spaces}]"
        
        IO.puts " #{progress_bar} #{percentage}% #{description}"
        IO.puts "    #{file}"
        
        if redshift > 0.5 do
          recommendations = Spacetime.Physics.Redshift.get_recommendations(file, redshift)
          IO.puts "    Recommendations:"
          Enum.each(recommendations, fn rec -> IO.puts "      - #{rec}" end)
        end
        
        IO.puts ""
      end)
    end
  end

  defp find_code_files do
    patterns = ["*.ex", "*.exs", "*.js", "*.ts", "*.py", "*.rb", "*.java", "*.go", "*.rs", "*.cpp", "*.c", "*.h"]
    
    patterns
    |> Enum.flat_map(fn pattern ->
      case File.ls(".") do
        {:ok, files} -> 
          files 
          |> Enum.filter(&String.ends_with?(&1, String.trim_leading(pattern, "*")))
        _ -> []
      end
    end)
    |> Enum.uniq()
  end
end
