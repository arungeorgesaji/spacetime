defmodule Spacetime.CLI.Commands.EventHorizon do
  def run do
    IO.puts "Scanning for Event Horizon commits..."
    
    commits = get_all_commits()
    
    event_horizons = Enum.filter(commits, fn commit_id ->
      status = Spacetime.Physics.EventHorizon.get_event_horizon_status(commit_id)
      status.event_horizon
    end)
    
    if Enum.empty?(event_horizons) do
      IO.puts "No Event Horizon commits detected"
      IO.puts "Create one with 'spacetime commit --event-horizon' for breaking changes"
    else
      IO.puts "\nEVENT HORIZON COMMITS DETECTED:"
      IO.puts "=" <> String.duplicate("=", 50)
      
      Enum.each(event_horizons, fn commit_id ->
        show_event_horizon_details(commit_id)
      end)
    end
  end

  defp get_all_commits do
    objects = Spacetime.SCM.ObjectParser.list_objects()
    
    objects
    |> Enum.filter(fn {_, type} -> type == "commit" end)
    |> Enum.map(fn {id, _} -> id end)
  end

  defp show_event_horizon_details(commit_id) do
    status = Spacetime.Physics.EventHorizon.get_event_horizon_status(commit_id)
    
    IO.puts "\nCommit: #{String.slice(commit_id, 0, 8)}"
    IO.puts "   Commitment: #{String.slice(status.commitment, 0, 16)}..."
    IO.puts "   Risks: #{Enum.join(status.risks, ", ")}"
    
    case Spacetime.Physics.EventHorizon.verify_migration(commit_id) do
      {:ok, message} ->
        IO.puts "   #{message}"
      {:warning, message} ->
        IO.puts "   #{message}"
    end
    
    case Spacetime.SCM.ObjectParser.read_commit(commit_id) do
      {:ok, commit_data} ->
        message_preview = String.slice(commit_data.message, 0, 100) <> "..."
        IO.puts "   Message: #{message_preview}"
      _ -> nil
    end
  end

  def create_event_horizon(message, files) do
    IO.puts "CREATING EVENT HORIZON COMMIT"
    IO.puts "This commit cannot be reverted once merged!"
    
    changes = analyze_changes(files)
    
    if Enum.empty?(changes) do
      IO.puts "No changes detected for Event Horizon commit"
    end
    
    if Spacetime.Physics.EventHorizon.should_be_event_horizon?(nil, changes) do
      IO.puts "Changes qualify for Event Horizon status"
      
      commit_params = %{
        message: message,
        author: get_author_info(),
        event_horizon: true
      }
      
      commit_id = Spacetime.Physics.EventHorizon.create_event_horizon_commit(commit_params, changes)
      
      IO.puts "Event Horizon commit created: #{String.slice(commit_id, 0, 8)}"
      IO.puts "Migration guide created: event_horizon_#{String.slice(commit_id, 0, 8)}.md"
    else
      IO.puts "Changes do not qualify for Event Horizon status"
      IO.puts "Event Horizon commits are for breaking changes, migrations, and major refactors"
    end
  end

  defp analyze_changes(files) do
    Enum.map(files, fn file_path ->
      if File.exists?(file_path) do
        content = File.read!(file_path)
        {file_path, content}
      else
        {file_path, :deleted}
      end
    end)
  end

  defp get_author_info do
    "Cosmic Developer <cosmic@spacetime.dev>"
  end
end
