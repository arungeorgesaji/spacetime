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

  def get_current_branch do
    head_content = File.read!(".spacetime/HEAD") |> String.trim()
    case head_content do
      "ref: " <> ref -> String.replace(ref, "refs/heads/", "")
      _ -> "detached"
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
end
