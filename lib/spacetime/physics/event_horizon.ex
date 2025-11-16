defmodule Spacetime.Physics.EventHorizon do
  @code_extensions [
    ".ex", ".exs", ".erl", ".beam", ".js", ".jsx", ".ts", ".tsx", ".py", ".rb", ".java", ".kt", ".scala", ".groovy", ".go", ".rs", ".c", ".h", ".cpp", ".hpp", ".cc", ".cs", ".php", ".swift", ".m", ".dart", ".lua", ".sh", ".bash", ".yaml", ".yml", ".json", ".lock", ".toml", ".ini", ".sql"                   ]

  def should_be_event_horizon?(commit_id, changes) do
    breaking_changes = detect_breaking_changes(changes)
    migration_changes = detect_migration_changes(changes)
    major_refactor = detect_major_refactor(changes)
    
    breaking_changes or migration_changes or major_refactor
  end

  def detect_breaking_changes(changes) do
    Enum.any?(changes, fn {file_path, _content} ->
      Enum.any?(@code_extensions, &String.ends_with?(file_path, &1)) and
        contains_breaking_patterns?(file_path)
    end)
  end

  defp contains_breaking_patterns?(file_path) do
    if File.exists?(file_path) do
      content = File.read!(file_path)

      breaking_patterns = [

        ~r/BREAKING CHANGE/i,
        ~r/MAJOR CHANGE/i,
        ~r/Major.*version/i,
        ~r/remove.*API/i,
        ~r/rename.*API/i,
        ~r/deprecate.*API/i,

        ~r/@deprecated/i,
        ~r/@obsolete/i,
        ~r/@removal/i,
        ~r/TODO:? remove/i,

        ~r/def.*obsolete/,
        ~r/defp.*remove/,
        ~r/raise.*NotImplementedError/,
        ~r/Protocol.*changed/i,
        ~r/behaviour.*removed/i,

        ~r/pub\s+trait.*removed/,
        ~r/pub\s+fn.*changed/,
        ~r/deprecated.*true/i,

        ~r/def\s+.*removed/,
        ~r/class\s+.*removed/,
        ~r/@deprecated/,
        ~r/@abstractmethod.*changed/,

        ~r/public\s+interface.*removed/,
        ~r/public\s+class.*removed/,
        ~r/@Deprecated/,
        ~r/throws\s+.*RemovedException/,

        ~r/export\s+interface.*removed/,
        ~r/export\s+function.*removed/,
        ~r/breaking api/i,
        ~r/remove.*endpoint/i,

        ~r/router.*delete/,        
        ~r/remove_route/,          
        ~r/schema.*change/,        
        ~r/migration.*drop/i,

        ~r/func\s+\w+.*removed/,
        ~r/interface\s+\w+.*removed/
      ]

      Enum.any?(breaking_patterns, &Regex.match?(&1, content))
    else
      false
    end
  end

  defp detect_migration_changes(changes) do
    Enum.any?(changes, fn {file_path, _content} ->
      String.contains?(file_path, ["migration", "migrate", "schema"]) or
      String.ends_with?(file_path, [".sql", ".migration"])
    end)
  end

  defp detect_major_refactor(changes) do
    renamed_files = Enum.count(changes, fn {file_path, _content} ->
      String.contains?(file_path, "rename") or
      String.contains?(file_path, "move")
    end)
    
    deleted_files = Enum.count(changes, fn {file_path, content} ->
      content == :deleted
    end)
    
    (renamed_files + deleted_files) >= 3  
  end

  def create_event_horizon_commit(commit_params, changes) do
    tree_entries = Enum.map(changes, fn {file_path, content} ->
      case content do
        :deleted ->
          nil
        
        binary_content when is_binary(binary_content) ->
          blob_id = Spacetime.SCM.ObjectParser.store_blob(binary_content)
          %{
            name: file_path,
            type: :blob,
            id: blob_id,
            mode: "100644"
          }
      end
    end)
    |> Enum.filter(&(&1 != nil))
    
    tree_id = Spacetime.SCM.ObjectParser.store_tree(tree_entries)
    
    commitment = generate_commitment(changes)
    
    warning = """
          EVENT HORIZON COMMIT
  This commit represents a point of no return.
  Once merged, it cannot be reverted due to:
  - Breaking API changes
  - Database migrations
  - Major structural refactoring

  Proceed with extreme caution!
  """

    enhanced_params = %{
      tree: tree_id,
      message: commit_params.message <> "\n" <> warning,
      author: commit_params[:author] || "Unknown <unknown@localhost>",
      committer: commit_params[:committer] || commit_params[:author] || "Unknown <unknown@localhost>",
      timestamp: commit_params[:timestamp] || DateTime.utc_now() |> DateTime.to_iso8601(),
      event_horizon: true,
      commitment: commitment
    }
    
    enhanced_params = case get_last_commit() do
      nil -> enhanced_params
      parent_id -> Map.put(enhanced_params, :parent, parent_id)
    end

    commit_id = Spacetime.SCM.Internals.create_commit(enhanced_params)
    
    update_head_ref(commit_id)
    
    clear_staging_area()

    create_migration_guidance(commit_id, changes)

    commit_id
  end

  defp get_last_commit do
    head_ref = Spacetime.Repo.get_head()

    normalized =
      head_ref
      |> String.replace("ref: ", "")
      |> String.trim()

    ref_path = ".spacetime/#{normalized}"

    if File.exists?(ref_path) do
      content = File.read!(ref_path) |> String.trim()
      if content != "", do: content, else: nil
    else
      nil
    end
  end

  defp update_head_ref(commit_id) do
    head_ref = Spacetime.Repo.get_head()

    normalized =
      head_ref
      |> String.replace("ref: ", "")
      |> String.trim()

    ref_path = ".spacetime/#{normalized}"

    File.mkdir_p!(Path.dirname(ref_path))

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
        if is_binary(content) do
          content_hash = :crypto.hash(:sha256, content) |> Base.encode16(case: :lower)
          "#{path}:#{content_hash}"
        else
          "#{path}:deleted"
        end
      end)
      |> Enum.sort()
      |> Enum.join("|")
    
    :crypto.hash(:sha256, change_hash) |> Base.encode16(case: :lower)
  end

  defp create_migration_guidance(commit_id, changes) do
    guidance = """
    # Event Horizon Migration Guide
    Commit: #{commit_id}
    Date: #{DateTime.utc_now() |> DateTime.to_iso8601()}
    
    ## Breaking Changes Detected:
    #{Enum.map_join(changes, "\n", fn {file, _} -> "- #{file}" end)}
    
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
    
    File.write!(".spacetime/migration_guides/event_horizon_#{String.slice(commit_id, 0, 8)}.md", guidance)
  end

  def verify_migration(commit_id) do
    case Spacetime.SCM.ObjectParser.read_commit(commit_id) do
      {:ok, commit_data} ->
        if commit_data[:event_horizon] do
          check_dependent_migrations(commit_data)
        else
          {:ok, "Not an Event Horizon commit"}
        end
        
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp check_dependent_migrations(commit_data) do
    files = commit_data[:files] || []
    
    outdated_dependents = Enum.filter(files, fn file ->
      has_outdated_references?(file)
    end)
    
    if Enum.empty?(outdated_dependents) do
      {:ok, "All dependencies migrated"}
    else
      {:warning, "Outdated dependencies found: #{Enum.join(outdated_dependents, ", ")}"}
    end
  end

  defp has_outdated_references?(file_path) do
    if File.exists?(file_path) do
      content = File.read!(file_path)
      
      patterns = [
        ~r/import.*#{Path.basename(file_path, Path.extname(file_path))}/,
        ~r/require.*#{Path.basename(file_path, Path.extname(file_path))}/,
        ~r/from.*#{Path.basename(file_path, Path.extname(file_path))}/
      ]
      
      Enum.any?(patterns, &Regex.match?(&1, content))
    else
      false  
    end
  end

  def get_event_horizon_status(commit_id) do
    case Spacetime.SCM.ObjectParser.read_commit(commit_id) do
      {:ok, commit_data} ->
        if commit_data[:event_horizon] do
          %{
            event_horizon: true,
            commitment: commit_data[:commitment] |> List.first(),
            risks: calculate_risks(commit_data),
            migration_required: true
          }
        else
          %{event_horizon: false}
        end
        
      {:error, reason} ->
        %{error: reason}
    end
  end

  defp calculate_risks(commit_data) do
    risks = []
    
    risks = if String.contains?(commit_data.message |> String.split("\n", trim: true) |> List.first(), "API"), do: ["API Breaking Change" | risks], else: risks
    risks = if String.contains?(commit_data.message |> String.split("\n", trim: true) |> List.first(), "migration"), do: ["Database Migration" | risks], else: risks
    risks = if String.contains?(commit_data.message |> String.split("\n", trim: true) |> List.first() , "refactor"), do: ["Major Refactor" | risks], else: risks
    
    risks
  end
end
