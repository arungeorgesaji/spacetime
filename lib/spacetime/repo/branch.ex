defmodule Spacetime.Repo.Branch do
  def list_branches do
    branches_dir = ".spacetime/refs/heads"
    
    if File.exists?(branches_dir) do
      File.ls!(branches_dir)
    else
      []
    end
  end

  def get_branch_commit(branch_name) do
    branch_path = ".spacetime/refs/heads/#{branch_name}"
    
    if File.exists?(branch_path) do
      File.read!(branch_path) |> String.trim()
    else
      nil
    end
  end

  def create_branch(branch_name, start_commit \\ nil) do
    commit = start_commit || get_current_commit()
    
    if commit do
      branch_path = ".spacetime/refs/heads/#{branch_name}"
      File.write!(branch_path, commit)
      {:ok, branch_name}
    else
      {:error, "No commit to branch from"}
    end
  end

  def get_current_branch() do
    case File.read(".spacetime/HEAD") do
      {:ok, content} ->
        content
        |> String.trim()
        |> String.replace("ref: refs/heads/", "")
        
      {:error, _} ->
        "main" 
    end
  end

  def get_current_commit do
    branch_name = get_current_branch()
    get_branch_commit(branch_name)
  end

  def get_branch_history(branch_name) do
    case get_branch_commit(branch_name) do
      nil -> []
      commit_id -> Spacetime.SCM.ObjectParser.get_commit_history(commit_id)
    end
  end

  def checkout_branch(branch_name) do
    branches = list_branches()
    
    if branch_name in branches do
      head_content = "ref: refs/heads/#{branch_name}"
      File.write!(".spacetime/HEAD", head_content)
      {:ok, branch_name}
    else
      {:error, "branch '#{branch_name}' not found"}
    end
  end
end
