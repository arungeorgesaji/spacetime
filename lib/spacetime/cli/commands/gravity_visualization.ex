defmodule Spacetime.CLI.Commands.GravityVisualization do
  alias Spacetime.Physics.Gravity
  alias Spacetime.Physics.Quantum

  def run(options \\ %{}) do
    IO.puts("Spacetime Gravity Visualization")
    IO.puts("=" <> String.duplicate("=", 50))
    
    branches = Spacetime.Repo.Branch.list_branches()
    
    if Enum.empty?(branches) do
      IO.puts("No branches found in repository")
    end
    
    gravitational_data = calculate_gravitational_data(branches)
    
    case options.format do
      "text" -> render_text(gravitational_data, options)
      "graph" -> render_ascii_graph(gravitational_data, options)
      "json" -> render_json(gravitational_data, options)
      _ -> render_text(gravitational_data, options)
    end
  end

  defp calculate_gravitational_data(branches) do
    Enum.map(branches, fn branch ->
      history = Spacetime.Repo.Branch.get_branch_history(branch)
      mass_data = Gravity.calculate_branch_mass(branch, history)
      
      %{
        branch: branch,
        mass: mass_data.total,
        commit_count: length(history),
        history: history,
        gravitational_pull: calculate_gravitational_pull(branch, branches),
        is_current: branch == Spacetime.Repo.Branch.get_current_branch()
      }
    end)
    |> Enum.filter(fn data -> data.mass >= 0.1 end) 
    |> Enum.sort_by(& &1.mass, :desc)
  end

  defp calculate_gravitational_pull(current_branch, all_branches) do
    current_history = Spacetime.Repo.Branch.get_branch_history(current_branch)
    current_mass = Gravity.calculate_branch_mass(current_branch, current_history).total
    
    Enum.reduce(all_branches, %{}, fn other_branch, acc ->
      if other_branch != current_branch do
        other_history = Spacetime.Repo.Branch.get_branch_history(other_branch)
        other_mass = Gravity.calculate_branch_mass(other_branch, other_history).total
        
        force = calculate_gravitational_force(current_mass, other_mass, current_history, other_history)
        
        if force > 0.01 do
          Map.put(acc, other_branch, %{
            force: force,
            direction: determine_direction(current_branch, other_branch),
            shared_commits: count_shared_commits(current_history, other_history)
          })
        else
          acc
        end
      else
        acc
      end
    end)
  end

  defp calculate_gravitational_force(mass1, mass2, history1, history2) do
    g_constant = 6.67430e-11 
    shared_ratio = shared_commit_ratio(history1, history2)
    
    distance = if shared_ratio > 0, do: 1.0 / shared_ratio, else: 100.0
    
    (g_constant * mass1 * mass2) / :math.pow(distance, 2)
  end

  defp shared_commit_ratio(history1, history2) do
    commits1 = Enum.map(history1, & &1.id)
    commits2 = Enum.map(history2, & &1.id)
    shared = MapSet.intersection(MapSet.new(commits1), MapSet.new(commits2)) |> MapSet.size()
    
    total = max(MapSet.size(MapSet.new(commits1)), MapSet.size(MapSet.new(commits2)))
    
    if total > 0, do: shared / total, else: 0.0
  end

  defp count_shared_commits(history1, history2) do
    commits1 = Enum.map(history1, & &1.id)
    commits2 = Enum.map(history2, & &1.id)
    MapSet.intersection(MapSet.new(commits1), MapSet.new(commits2)) |> MapSet.size()
  end

  defp determine_direction(branch1, branch2) do
    :toward 
  end

  defp render_text(gravitational_data, options) do
    IO.puts("\nBranch Gravitational Analysis")
    IO.puts(String.duplicate("-", 60))
    
    Enum.each(gravitational_data, fn data ->
      current_indicator = if data.is_current, do: " 🌟", else: ""
      IO.puts("#{data.branch}#{current_indicator}")
      IO.puts("  Mass: #{:erlang.float_to_binary(data.mass, decimals: 2)}")
      IO.puts("  Commits: #{data.commit_count}")
      
      if map_size(data.gravitational_pull) > 0 do
        IO.puts("  Gravitational Pull:")
        Enum.each(data.gravitational_pull, fn {target_branch, pull_data} ->
          force_str = :erlang.float_to_binary(pull_data.force, decimals: 4)
          IO.puts("    ↳ #{target_branch}: #{force_str} (shared: #{pull_data.shared_commits})")
        end)
      else
        IO.puts("  Gravitational Pull: (isolated)")
      end
      IO.puts("")
    end)
    
    if options.show_entanglements do
      render_quantum_entanglements()
    end
    
    render_gravitational_summary(gravitational_data)
  end

  defp render_quantum_entanglements do
    entanglements = Quantum.list_entanglements()
    
    if Enum.empty?(entanglements) do
      IO.puts("No quantum entanglements")
    else
      IO.puts("\nQuantum Entanglements:")
      Enum.each(entanglements, fn entanglement ->
        direction = if entanglement.bidirectional, do: "↔", else: "→"
        IO.puts("  #{entanglement.branch1} #{direction} #{entanglement.branch2}")
        IO.puts("    Strength: #{entanglement.strength}, Syncs: #{entanglement.sync_count}")
      end)
    end
  end

  defp render_gravitational_summary(gravitational_data) do
    total_mass = Enum.reduce(gravitational_data, 0, &(&2 + &1.mass))
    avg_mass = if length(gravitational_data) > 0, do: total_mass / length(gravitational_data), else: 0
    heaviest = List.first(gravitational_data)
    lightest = List.last(gravitational_data)
    
    IO.puts("\nGravitational Summary:")
    IO.puts("  Total Repository Mass: #{:erlang.float_to_binary(total_mass, decimals: 2)}")
    IO.puts("  Average Branch Mass: #{:erlang.float_to_binary(avg_mass, decimals: 2)}")
    IO.puts("  Heaviest Branch: #{heaviest.branch} (#{:erlang.float_to_binary(heaviest.mass, decimals: 2)})")
    IO.puts("  Lightest Branch: #{lightest.branch} (#{:erlang.float_to_binary(lightest.mass, decimals: 2)})")
    IO.puts("  Branch Count: #{length(gravitational_data)}")
  end

  defp render_ascii_graph(gravitational_data, options) do
    IO.puts("\nGravitational Field Map")
    IO.puts(String.duplicate("=", 70))
    
    branches = Enum.map(gravitational_data, & &1.branch)
    
    IO.puts("\nBranch Relationships:")
    IO.puts("(Thicker lines = stronger gravitational pull)")
    IO.puts("")
    
    Enum.each(gravitational_data, fn data ->
      current_indicator = if data.is_current, do: " ← YOU ARE HERE", else: ""
      IO.puts("#{data.branch}#{current_indicator}")
      
      if map_size(data.gravitational_pull) > 0 do
        sorted_pulls = Enum.sort_by(data.gravitational_pull, & -&1.force)
        
        Enum.each(sorted_pulls, fn {target_branch, pull_data} ->
          line_strength = cond do
            pull_data.force > 0.1 -> "━━━━━━"
            pull_data.force > 0.01 -> "━━━━"
            pull_data.force > 0.001 -> "━━"
            true -> "─"
          end
          
          force_str = :erlang.float_to_binary(pull_data.force, decimals: 4)
          IO.puts("    #{line_strength}➤ #{target_branch} (force: #{force_str})")
        end)
      else
        IO.puts("    ───── (isolated)")
      end
      IO.puts("")
    end)
    
    IO.puts("\nMass Distribution:")
    max_mass = gravitational_data |> Enum.map(& &1.mass) |> Enum.max()
    
    Enum.each(gravitational_data, fn data ->
      bar_length = trunc((data.mass / max_mass) * 30)
      bar = String.duplicate("█", bar_length) |> String.pad_trailing(30)
      mass_str = :erlang.float_to_binary(data.mass, decimals: 2)
      current_indicator = if data.is_current, do: " ←", else: ""
      IO.puts("#{String.pad_trailing(data.branch, 15)}: #{bar} #{mass_str}#{current_indicator}")
    end)
  end

  defp render_json(gravitational_data, options) do
    json_data = %{
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      branches: Enum.map(gravitational_data, fn data ->
        %{
          branch: data.branch,
          mass: data.mass,
          commit_count: data.commit_count,
          is_current: data.is_current,
          gravitational_pull: data.gravitational_pull
        }
      end),
      summary: calculate_summary(gravitational_data)
    }
    
    IO.puts(Jason.encode!(json_data, pretty: true))
  end

  defp calculate_summary(gravitational_data) do
    total_mass = Enum.reduce(gravitational_data, 0, &(&2 + &1.mass))
    branch_count = length(gravitational_data)
    
    %{
      total_mass: total_mass,
      average_mass: if(branch_count > 0, do: total_mass / branch_count, else: 0),
      branch_count: branch_count,
      heaviest_branch: gravitational_data |> List.first() |> Map.get(:branch),
      lightest_branch: gravitational_data |> List.last() |> Map.get(:branch)
    }
  end
end
