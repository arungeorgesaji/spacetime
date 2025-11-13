defmodule Spacetime.CLI.Commands.RedshiftStatus do
  def run do
    IO.puts "Scanning for redshift in spacetime continuum..."
    
    if not File.exists?(".spacetime/config") do
      IO.puts "Not a spacetime repository"
      IO.puts "Run 'spacetime init' to begin"
    end
    
    commit_history = get_commit_history()
    
    files = find_code_files()
    
    if Enum.empty?(files) do
      IO.puts "No code files found to analyze"
    else
      IO.puts "\nRedshift Analysis:"
      IO.puts "=" <> String.duplicate("=", 50)
      
      files
      |> Enum.map(fn file ->
        redshift = Spacetime.Physics.Redshift.calculate_redshift(file, commit_history)
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
        
        show_last_commit_info(file, commit_history)
        
        if redshift > 0.5 do
          recommendations = Spacetime.Physics.Redshift.get_recommendations(file, redshift)
          IO.puts "    Recommendations:"
          Enum.each(recommendations, fn rec -> IO.puts "      - #{rec}" end)
        end
        
        IO.puts ""
      end)
    end
  end

  defp get_commit_history do
    objects = Spacetime.SCM.ObjectParser.list_objects()
    
    commit_ids = objects
    |> Enum.filter(fn {_, type} -> type == "commit" end)
    |> Enum.map(fn {id, _} -> id end)
    
    if Enum.any?(commit_ids) do
      latest_commit = List.first(commit_ids)
      Spacetime.SCM.ObjectParser.get_commit_history(latest_commit)
    else
      []
    end
  end

  defp show_last_commit_info(file_path, commit_history) do
    latest_commit = Spacetime.SCM.Internals.find_latest_commit_for_file(file_path, commit_history)
    
    case latest_commit do
      %{id: commit_id, data: commit_data} ->
        case commit_data[:timestamp] do
          [timestamp | _] ->
            {:ok, commit_time, _} = DateTime.from_iso8601(timestamp)
            days_ago = DateTime.diff(DateTime.utc_now(), commit_time, :day)
            IO.puts "    Last modified: #{days_ago} days ago (commit #{String.slice(commit_id, 0, 8)})"
          _ ->
            IO.puts "    Last modified: unknown"
        end
      _ ->
        IO.puts "    Last modified: never committed"
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
