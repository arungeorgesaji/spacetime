defmodule Spacetime.CLI.Commands.CosmicCommit do
  def run(message) when is_binary(message) do
    IO.puts "Creating cosmic commit..."
    
    staged_files = Spacetime.Repo.get_staged_files()
    
    if Enum.empty?(staged_files) do
      IO.puts "No files staged for commit"
      IO.puts "Use 'spacetime add <file>' to stage files first"
    end
    
    tree_entries = Enum.map(staged_files, fn file ->
      %{
        name: file["path"],
        type: :blob,
        id: file["blob_id"],
        mode: "100644"
      }
    end)
    
    tree_id = Spacetime.SCM.ObjectParser.store_tree(tree_entries)
    
    parent_commit = get_parent_commit()
    
    commit_params = %{
      tree: tree_id,
      message: message,
      author: get_author_info(),
      committer: "Spacetime SCM <system@spacetime.dev>",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
    
    commit_params = if parent_commit do
      Map.put(commit_params, :parent, parent_commit)
    else
      commit_params
    end
    
    commit_id = Spacetime.SCM.ObjectParser.store_commit(commit_params)
    
    update_branch_ref(commit_id)
    
    Spacetime.Repo.clear_staging()
    
    IO.puts "Created commit: #{String.slice(commit_id, 0, 8)}"
    IO.puts "#{message}"
    IO.puts "#{length(staged_files)} files changed"
    
    calculate_initial_redshift(staged_files, commit_id)
  end

  defp get_parent_commit do
    head_ref = Spacetime.Repo.get_head()
    ref_path = ".spacetime/#{head_ref}"
    
    if File.exists?(ref_path) do
      File.read!(ref_path) |> String.trim()
    else
      nil
    end
  end

  defp update_branch_ref(commit_id) do
    head_ref = Spacetime.Repo.get_head()
    ref_path = ".spacetime/#{head_ref}"
    File.write!(ref_path, commit_id)
  end

  defp get_author_info do
    "Cosmic Developer <cosmic@spacetime.dev>"
  end

  defp calculate_initial_redshift(staged_files, commit_id) do
    IO.puts "Calculating initial redshift values..."
    
    Enum.each(staged_files, fn file ->
      redshift = Spacetime.Physics.Redshift.calculate_redshift(file["path"])
      if redshift > 0.3 do
        IO.puts "   #{file["path"]} has initial redshift: #{Float.round(redshift * 100, 1)}%"
      end
    end)
  end
end
