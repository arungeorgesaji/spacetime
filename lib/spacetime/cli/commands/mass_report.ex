defmodule Spacetime.CLI.Commands.MassReport do
  def run do
    IO.puts "Calculating cosmic masses..."
    
    branches = Spacetime.Repo.Branch.list_branches()
    
    if Enum.empty?(branches) do
      IO.puts "No branches found"
    end
    
    IO.puts "\nBranch Mass Report:"
    IO.puts "=" <> String.duplicate("=", 60)
    
    branches
    |> Enum.map(fn branch_name ->
      history = Spacetime.Repo.Branch.get_branch_history(branch_name)
      mass_data = Spacetime.Physics.Gravity.calculate_branch_mass(branch_name, history)
      escape_velocity = Spacetime.Physics.Gravity.calculate_escape_velocity(mass_data.total)
      
      {branch_name, mass_data, escape_velocity}
    end)
    |> Enum.sort_by(fn {_, mass_data, _} -> -mass_data.total end)
    |> Enum.each(fn {branch_name, mass_data, escape_velocity} ->
      current_indicator = if branch_name == Spacetime.Repo.Branch.get_current_branch(), do: " 🌟", else: ""
      gravity_desc = Spacetime.Physics.Gravity.describe_gravity(mass_data.total)
      merge_difficulty = Spacetime.Physics.Gravity.predict_merge_difficulty(escape_velocity)
      
      IO.puts "\n#{branch_name}#{current_indicator}"
      IO.puts "  Mass: #{Float.round(mass_data.total, 2)} (#{gravity_desc})"
      IO.puts "  Escape Velocity: #{Float.round(escape_velocity, 3)}"
      IO.puts "  Merge Difficulty: #{merge_difficulty}"
      
      IO.puts "  Components:"
      IO.puts "    Size: #{Float.round(mass_data.components.size, 2)}"
      IO.puts "    Age: #{Float.round(mass_data.components.age, 2)}"
      IO.puts "    Complexity: #{Float.round(mass_data.components.complexity, 2)}"
      IO.puts "    Redshift: #{Float.round(mass_data.components.redshift, 2)}"
    end)
    
    show_gravitational_pulls(branches)
  end

  defp show_gravitational_pulls(branches) do
    IO.puts "\nGravitational Relationships:"
    IO.puts "-" <> String.duplicate("-", 50)
    
    branch_masses = Enum.map(branches, fn branch_name ->
      history = Spacetime.Repo.Branch.get_branch_history(branch_name)
      mass_data = Spacetime.Physics.Gravity.calculate_branch_mass(branch_name, history)
      {branch_name, mass_data.total}
    end)
    
    for {branch1, mass1} <- branch_masses,
        {branch2, mass2} <- branch_masses,
        branch1 != branch2 do
      
      pull = Spacetime.Physics.Gravity.calculate_gravitational_pull(mass1, mass2)
      
      if pull > 0.001 do  
        IO.puts "  #{branch1} ←#{Float.round(pull, 4)}→ #{branch2}"
      end
    end
  end
end
