defmodule Spacetime.Physics.Gravity do
  @gravitational_constant 6.67430e-11  

  def calculate_branch_mass(branch_name, commit_history) do
    size_mass = calculate_size_mass(commit_history)
    age_mass = calculate_age_mass(commit_history)
    complexity_mass = calculate_complexity_mass(commit_history)
    redshift_mass = calculate_redshift_mass(commit_history)
    
    total_mass = (size_mass * 0.4) + (age_mass * 0.3) + (complexity_mass * 0.2) + (redshift_mass * 0.1)
    
    %{
      total: total_mass,
      components: %{
        size: size_mass,
        age: age_mass,
        complexity: complexity_mass,
        redshift: redshift_mass
      }
    }
  end

  defp calculate_size_mass(commit_history) do
    total_files = count_files_in_history(commit_history)
    total_loc = calculate_total_loc(commit_history)
    
    (total_files * 0.1) + (total_loc * 0.001)
  end

  defp calculate_age_mass(commit_history) do
    case commit_history do
      [%{data: %{timestamp: [latest | _]}} | _] ->
        {:ok, latest_time, _} = DateTime.from_iso8601(latest)
        now = DateTime.utc_now()
        days_old = DateTime.diff(now, latest_time, :day)
        
        :math.log(days_old + 1) * 0.5
        
      _ -> 0.0
    end
  end

  defp calculate_complexity_mass(commit_history) do
    files = get_all_files_from_history(commit_history)
    
    complexity_sum = Enum.reduce(files, 0, fn file_path, acc ->
      if File.exists?(file_path) do
        content = File.read!(file_path)
        
        lines = String.split(content, "\n") |> length()
        functions = count_functions(content)
        imports = count_imports(content)
        
        acc + (lines * 0.01) + (functions * 0.1) + (imports * 0.05)
      else
        acc
      end
    end)
    
    complexity_sum
  end

  defp calculate_redshift_mass(commit_history) do
    files = get_all_files_from_history(commit_history)
    
    redshift_sum = Enum.reduce(files, 0, fn file_path, acc ->
      redshift = Spacetime.Physics.Redshift.calculate_redshift(file_path, commit_history)
      acc + (redshift * 10)  
    end)
    
    redshift_sum
  end

  def calculate_escape_velocity(mass, distance \\ 1.0) do
    :math.sqrt(2 * @gravitational_constant * mass / distance)
  end

  def calculate_gravitational_pull(mass1, mass2, distance \\ 1.0) do
    (@gravitational_constant * mass1 * mass2) / :math.pow(distance, 2)
  end

  def describe_gravity(mass) when mass < 10, do: "Light"
  def describe_gravity(mass) when mass < 50, do: "Moderate" 
  def describe_gravity(mass) when mass < 100, do: "Heavy"
  def describe_gravity(_mass), do: "Supermassive"

  def predict_merge_difficulty(escape_velocity) when escape_velocity < 0.1, do: "Trivial"
  def predict_merge_difficulty(escape_velocity) when escape_velocity < 0.5, do: "Easy"
  def predict_merge_difficulty(escape_velocity) when escape_velocity < 1.0, do: "Moderate"
  def predict_merge_difficulty(escape_velocity) when escape_velocity < 2.0, do: "Difficult"
  def predict_merge_difficulty(_escape_velocity), do: "Extreme"

  defp count_files_in_history(commit_history) do
    commit_history
    |> Enum.flat_map(fn %{id: commit_id} ->
      Spacetime.SCM.Internals.get_commit_files(commit_id)
    end)
    |> Enum.uniq()
    |> length()
  end

  defp calculate_total_loc(commit_history) do
    files = get_all_files_from_history(commit_history)
    
    Enum.reduce(files, 0, fn file_path, acc ->
      if File.exists?(file_path) do
        content = File.read!(file_path)
        lines = String.split(content, "\n") |> length()
        acc + lines
      else
        acc
      end
    end)
  end

  defp get_all_files_from_history(commit_history) do
    commit_history
    |> Enum.flat_map(fn %{id: commit_id} ->
      Spacetime.SCM.Internals.get_commit_files(commit_id)
    end)
    |> Enum.uniq()
  end

  defp count_functions(content) do
    patterns = [
      ~r/def\s+\w+/,
      ~r/function\s+\w+/,
      ~r/fun\s+\w+/,
      ~r/fn\s+/,
      ~r/\w+\s*\([^)]*\)\s*\{/
    ]
    
    Enum.reduce(patterns, 0, fn pattern, acc ->
      acc + length(Regex.scan(pattern, content))
    end)
  end

  defp count_imports(content) do
    patterns = [
      ~r/import\s+/,
      ~r/require\s+/,
      ~r/include\s+/,
      ~r/using\s+/
    ]
    
    Enum.reduce(patterns, 0, fn pattern, acc ->
      acc + length(Regex.scan(pattern, content))
    end)
  end
end
