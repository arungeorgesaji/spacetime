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
    Path.wildcard("**/*", match_dot: false)
    |> Enum.filter(fn path ->
      File.regular?(path) and text_file?(path)
    end)
  end

  defp text_file?(path) do
    case File.read(path) do
      {:ok, content} ->
        printable_ratio =
          content
          |> :binary.bin_to_list()
          |> Enum.count(fn c -> c in 9..13 or c in 32..126 end)
          |> then(&(&1 / max(byte_size(content), 1)))

        printable_ratio > 0.9
      _ ->
        false
    end
  end
end
