defmodule Spacetime.CLI.Commands.CosmicCommit do
  def run(message, event_horizon \\ false) when is_binary(message) do
    IO.puts "Creating cosmic commit..."

    staged_files = Spacetime.Repo.get_staged_files()

    if Enum.empty?(staged_files) do
      IO.puts "No files staged for commit"
      IO.puts "Use 'spacetime add <file>' to stage files first"
      return_nothing()
    else
      do_commit(message, staged_files, event_horizon)
    end
  end

  defp return_nothing(), do: nil

  defp do_commit(message, staged_files, event_horizon) do
    tree_entries =
      Enum.map(staged_files, fn file ->
        %{
          name: file["path"],
          type: :blob,
          id: file["blob_id"],
          mode: "100644"
        }
      end)

    tree_id = Spacetime.SCM.ObjectParser.store_tree(tree_entries)
    parent_commit = get_parent_commit()

    base_commit_params = %{
      tree: tree_id,
      message: message,
      author: get_author_info(),
      committer: "Spacetime SCM <system@spacetime.dev>",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    commit_params =
      if parent_commit,
        do: Map.put(base_commit_params, :parent, parent_commit),
        else: base_commit_params

    commit_id =
      if event_horizon do
        changes = Enum.map(staged_files, fn file ->
          {file["path"], File.read!(file["path"])}
        end)

        case Spacetime.Physics.EventHorizon.create_event_horizon_commit(commit_params, changes) do
          commit_id when is_binary(commit_id) ->
            finalize_commit(commit_id, staged_files, message, event_horizon: true)

          {:error, _} ->
            IO.puts "Event Horizon commit aborted."
            nil
        end
      else
        commit_id = Spacetime.SCM.ObjectParser.store_commit(commit_params)
        finalize_commit(commit_id, staged_files, message, event_horizon: false)
      end

    event_horizon_indicator = if event_horizon, do: " ⚫", else: ""

    IO.puts "Created commit#{event_horizon_indicator}: #{String.slice(commit_id, 0, 8)}"
    IO.puts "#{message}"
    IO.puts "#{length(staged_files)} files changed"

    calculate_initial_redshift(staged_files, commit_id)
    commit_id
  end

  defp get_parent_commit do
    head_ref = Spacetime.Repo.get_head()
    ref_path = ".spacetime/#{head_ref}"

    if File.exists?(ref_path),
      do: File.read!(ref_path) |> String.trim(),
      else: nil
  end

  defp update_branch_ref(commit_id) do
    head_ref = Spacetime.Repo.get_head()
    ref_path = ".spacetime/#{head_ref}"
    File.write!(ref_path, commit_id)
  end

  defp get_author_info do
    "Cosmic Developer <cosmic@spacetime.dev>"
  end

  defp calculate_initial_redshift(staged_files, _commit_id) do
    IO.puts "Calculating initial redshift values..."

    Enum.each(staged_files, fn file ->
      redshift = Spacetime.Physics.Redshift.calculate_redshift(file["path"])

      if redshift > 0.3 do
        IO.puts "   #{file["path"]} has initial redshift: #{Float.round(redshift * 100, 1)}%"
      end
    end)
  end

  defp finalize_commit(_commit_id, staged_files, message, opts \\ []) do
    event_horizon = Keyword.get(opts, :event_horizon, false)
    
    tree_entries = Enum.map(staged_files, fn file ->
      blob_id = Spacetime.SCM.ObjectParser.store_blob(File.read!(file["path"]))
      %{
        name: file["path"],
        type: :blob,
        id: blob_id,
        mode: "100644"
      }
    end)
    
    tree_id = Spacetime.SCM.ObjectParser.store_tree(tree_entries)
    
    commit_params = %{
      tree: tree_id,
      message: message,
      author: get_author_info(),
      committer: get_author_info(),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
    
    commit_params = case get_last_commit() do
      nil -> commit_params
      parent_id -> Map.put(commit_params, :parent, parent_id)
    end
    
    final_commit_id = if event_horizon do
      changes = Enum.map(staged_files, fn file ->
        {file["path"], File.read!(file["path"])}
      end)
      
      commitment = generate_commitment(changes)
      
      commit_params
      |> Map.put(:event_horizon, true)
      |> Map.put(:commitment, commitment)
      |> Spacetime.SCM.Internals.create_commit()
    else
      Spacetime.SCM.Internals.create_commit(commit_params)
    end
    
    update_head_ref(final_commit_id)
    
    clear_staging_area()
    
    IO.puts "Commit created: #{String.slice(final_commit_id, 0, 8)}"
    
    if event_horizon do
      IO.puts "EVENT HORIZON COMMIT - Cannot be reverted!"
      create_migration_guide(final_commit_id, staged_files)
    end
    
    final_commit_id
  end

  defp get_last_commit do
    head_ref = Spacetime.Repo.get_head()
    ref_path = ".spacetime/#{head_ref}"
    
    if File.exists?(ref_path) do
      content = File.read!(ref_path) |> String.trim()
      if content != "", do: content, else: nil
    else
      nil
    end
  end

  defp update_head_ref(commit_id) do
    head_ref = Spacetime.Repo.get_head()
    ref_path = ".spacetime/#{head_ref}"
    File.write!(ref_path, commit_id)
  end

  defp clear_staging_area do
    staging_dir = ".spacetime/staging"
    if File.exists?(staging_dir) do
      File.rm_rf!(staging_dir)
      File.mkdir_p!(staging_dir)
    end
  end

  defp generate_commitment(changes) do
    change_hash = 
      changes
      |> Enum.map(fn {path, content} -> 
        content_hash = :crypto.hash(:sha256, content) |> Base.encode16(case: :lower)
        "#{path}:#{content_hash}"
      end)
      |> Enum.sort()
      |> Enum.join("|")
    
    :crypto.hash(:sha256, change_hash) |> Base.encode16(case: :lower)
  end

  defp create_migration_guide(commit_id, staged_files) do
    file_list = Enum.map_join(staged_files, "\n", fn file -> "- #{file["path"]}" end)
    
    guidance = """
    # Event Horizon Migration Guide
    Commit: #{commit_id}
    Date: #{DateTime.utc_now() |> DateTime.to_iso8601()}
    
    ## Files Modified:
    #{file_list}
    
    ## Required Actions:
    1. Update all dependent services
    2. Run database migrations in order
    3. Update API documentation
    4. Notify all consumers of breaking changes
    
    ## Rollback Strategy:
    This commit cannot be reverted. Instead:
    - Create forward-fixing migrations
    - Implement feature flags if possible
    - Prepare roll-forward strategy
    """
    
    File.write!(".spacetime/event_horizon_#{String.slice(commit_id, 0, 8)}.md", guidance)
    IO.puts "Migration guide created: .spacetime/event_horizon_#{String.slice(commit_id, 0, 8)}.md"
  end
end
