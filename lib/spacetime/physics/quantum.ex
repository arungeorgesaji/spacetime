defmodule Spacetime.Physics.Quantum do
  alias Spacetime.SCM.Internals

  defmodule Entanglement do
    @derive [Jason.Encoder]
    defstruct [
      :id,
      :branch1,
      :branch2, 
      :strength,
      :bidirectional,
      :created_at,
      :last_sync,
      :sync_count,
      :config
    ]
  end

  @entanglements_file ".spacetime/quantum_entanglements.json"

  def create_entanglement(branch1, branch2, options \\ %{}) do
    unless branch_exists?(branch1) and branch_exists?(branch2) do
      {:error, "One or both branches do not exist"}
    end

    entanglements = load_entanglements()
    
    if entanglement_exists?(entanglements, branch1, branch2) do
      {:error, "Branches are already entangled"}
    end

    entanglement = %Entanglement{
      id: generate_entanglement_id(),
      branch1: branch1,
      branch2: branch2,
      strength: Map.get(options, :strength, "medium"),
      bidirectional: Map.get(options, :bidirectional, false),
      created_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      last_sync: nil,
      sync_count: 0,
      config: %{}
    }

    updated_entanglements = [entanglement | entanglements]
    save_entanglements(updated_entanglements)

    {:ok, entanglement}
  end

  def remove_entanglement(branch1, branch2) do
    entanglements = load_entanglements()
    
    updated_entanglements = Enum.reject(entanglements, fn e ->
      (e.branch1 == branch1 and e.branch2 == branch2) or
      (e.bidirectional and e.branch1 == branch2 and e.branch2 == branch1)
    end)
    
    if length(updated_entanglements) == length(entanglements) do
      {:error, "No entanglement found between #{branch1} and #{branch2}"}
    else
      save_entanglements(updated_entanglements)
      {:ok, :removed}
    end
  end

  def list_entanglements do
    load_entanglements()
  end

  def synchronize_entanglements(committed_branch, commit_id) do
    entanglements = load_entanglements()
    
    Enum.each(entanglements, fn entanglement ->
      if should_sync?(entanglement, committed_branch) do
        sync_entanglement(entanglement, committed_branch, commit_id)
      end
    end)
  end

  defp should_sync?(entanglement, committed_branch) do
    cond do
      entanglement.bidirectional ->
        entanglement.branch1 == committed_branch or entanglement.branch2 == committed_branch
      true ->
        entanglement.branch1 == committed_branch
    end
  end

  defp sync_entanglement(entanglement, committed_branch, commit_id) do
    target_branch = if entanglement.branch1 == committed_branch do
      entanglement.branch2
    else
      entanglement.branch1
    end

    IO.puts("Quantum sync: #{committed_branch} → #{target_branch}")
    
    case apply_commit_to_branch(target_branch, commit_id) do
      {:ok, _} ->
        update_entanglement_sync(entanglement)
        IO.puts("Quantum sync completed")
        
      {:error, reason} ->
        IO.puts("Quantum sync failed: #{reason}")
    end
  end

  defp apply_commit_to_branch(target_branch, commit_id) do
    branch_path = ".spacetime/refs/heads/#{target_branch}"
    File.write!(branch_path, commit_id)
    {:ok, :synced}
  end

  defp update_entanglement_sync(entanglement) do
    entanglements = load_entanglements()
    
    updated_entanglements = Enum.map(entanglements, fn e ->
      if e.id == entanglement.id do
        %{e | 
          last_sync: DateTime.utc_now() |> DateTime.to_iso8601(),
          sync_count: e.sync_count + 1
        }
      else
        e
      end
    end)
    
    save_entanglements(updated_entanglements)
  end

  defp load_entanglements do
    if File.exists?(@entanglements_file) do
      File.read!(@entanglements_file)
      |> Jason.decode!(keys: :atoms)
      |> Enum.map(&struct(Entanglement, &1))
    else
      []
    end
  end

  defp save_entanglements(entanglements) do
    json = Jason.encode!(entanglements, pretty: true)
    File.write!(@entanglements_file, json)
  end

  defp entanglement_exists?(entanglements, branch1, branch2) do
    Enum.any?(entanglements, fn e ->
      (e.branch1 == branch1 and e.branch2 == branch2) or
      (e.bidirectional and e.branch1 == branch2 and e.branch2 == branch1)
    end)
  end

  defp branch_exists?(branch_name) do
    File.exists?(".spacetime/refs/heads/#{branch_name}")
  end

  defp generate_entanglement_id do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16()
    |> String.downcase()
  end
end
