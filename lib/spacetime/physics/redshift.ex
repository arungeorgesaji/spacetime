defmodule Spacetime.Physics.Redshift do
  @redshift_threshold_days 30.0
  
  def calculate_redshift(file_path, commit_history \\ []) do
    age_factor = calculate_age_factor(file_path, commit_history)
    complexity_factor = calculate_complexity_factor(file_path)
    
    redshift = (age_factor * 0.7) + (complexity_factor * 0.3)
    
    max(0.0, min(1.0, redshift))
  end
  
  defp calculate_age_factor(file_path, _commit_history) do
    case get_file_age_days(file_path) do
      0 -> 0.0
      age_days -> 
        1.0 - :math.exp(-age_days / @redshift_threshold_days)
    end
  end
  
  defp get_file_age_days(file_path) do
    case File.stat(file_path) do
      {:ok, stat} ->
        {{year, month, day}, {hour, minute, second}} = stat.mtime
        birth_time =
          %DateTime{
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute,
            second: second,
            time_zone: "Etc/UTC",
            zone_abbr: "UTC",
            utc_offset: 0,
            std_offset: 0
          }
        
        current_time = DateTime.utc_now()
        seconds_diff = DateTime.diff(current_time, birth_time, :second)
        days_diff = div(seconds_diff, 86_400) 
        max(days_diff, 0)
      {:error, _} ->
        0
    end
  end
  
  defp calculate_complexity_factor(file_path) do
    if File.exists?(file_path) do
      content = File.read!(file_path)
      
      line_count = content |> String.split("\n") |> length()
      avg_line_length = byte_size(content) / max(line_count, 1)
      
      line_complexity = min(line_count / 100.0, 1.0)
      length_complexity = min(avg_line_length / 80.0, 1.0)
      
      (line_complexity * 0.6) + (length_complexity * 0.4)
    else
      0.0
    end
  end
  
  def describe_redshift(redshift) when redshift < 0.3, do: "Fresh"
  def describe_redshift(redshift) when redshift < 0.6, do: "Aging"
  def describe_redshift(redshift) when redshift < 0.8, do: "Redshifted"
  def describe_redshift(_redshift), do: "Critical Redshift"
  
  def get_recommendations(_file_path, redshift) do
    base_recommendations = [
      "Consider updating documentation",
      "Review for modern patterns"
    ]
    
    case redshift do
      r when r < 0.3 -> 
        ["Code is fresh - no action needed"]
      r when r < 0.6 ->
        ["Consider minor refactoring"] ++ base_recommendations
      r when r < 0.8 ->
        ["Plan for significant refactoring", "Update tests"] ++ base_recommendations
      _ ->
        ["Immediate refactoring required", "Consider complete rewrite"] ++ base_recommendations
    end
  end

  def analyze_repository_redshift(_options \\ %{}) do
    files = find_repository_files()
    
    files_data = Enum.map(files, fn file_path ->
      analyze_file_redshift(file_path)
    end)
    |> Enum.filter(& &1) 
    
    summary = calculate_redshift_summary(files_data)
    
    %{
      files: files_data,
      summary: summary,
      analyzed_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end

  defp find_repository_files do
    patterns = ["**/*"]
    
    patterns
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.filter(&File.regular?/1)
    |> Enum.reject(&String.starts_with?(&1, ".spacetime/"))
  end

  defp analyze_file_redshift(file_path) do
    case File.stat(file_path) do
      {:ok, stat} ->
        age_days = calculate_file_age_days(stat.mtime)
        change_count = get_file_change_count(file_path)
        redshift = calculate_redshift(file_path, [])
        factors = analyze_redshift_factors(file_path, age_days, change_count)
        
        %{
          path: file_path,
          redshift: redshift,
          age_days: age_days,
          change_count: change_count,
          factors: factors,
          last_change: get_last_change_date(file_path)
        }
        
      {:error, _} ->
        nil
    end
  end

  defp calculate_redshift_summary(files_data) do
    redshifts = Enum.map(files_data, & &1.redshift)
    total_files = length(files_data)
    
    if total_files > 0 do
      avg_redshift = Enum.sum(redshifts) / total_files
      max_redshift = Enum.max(redshifts)
      min_redshift = Enum.min(redshifts)
      
      distribution = %{
        critical: Enum.count(files_data, & &1.redshift >= 0.8),
        high: Enum.count(files_data, & &1.redshift >= 0.6 and &1.redshift < 0.8),
        medium: Enum.count(files_data, & &1.redshift >= 0.4 and &1.redshift < 0.6),
        low: Enum.count(files_data, & &1.redshift >= 0.2 and &1.redshift < 0.4),
        minimal: Enum.count(files_data, & &1.redshift < 0.2),
        blueshift: Enum.count(files_data, & &1.redshift < 0)
      }
      
      most_redshifted = files_data
        |> Enum.sort_by(& -&1.redshift)
        |> Enum.take(5)
        |> Enum.map(& {&1.path, &1.redshift})
      
      %{
        total_files: total_files,
        average_redshift: avg_redshift,
        max_redshift: max_redshift,
        min_redshift: min_redshift,
        distribution: distribution,
        most_redshifted: most_redshifted
      }
    else
      %{
        total_files: 0,
        average_redshift: 0.0,
        max_redshift: 0.0,
        min_redshift: 0.0,
        distribution: %{critical: 0, high: 0, medium: 0, low: 0, minimal: 0, blueshift: 0},
        most_redshifted: []
      }
    end
  end

  defp calculate_file_age_days(mtime) do
    now = DateTime.utc_now()
    {{year, month, day}, {hour, minute, second}} = mtime
    file_time = %DateTime{
      year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute,
      second: second,
      time_zone: "Etc/UTC",
      zone_abbr: "UTC",
      utc_offset: 0,
      std_offset: 0
    }
    DateTime.diff(now, file_time, :day)
  end

  defp get_file_change_count(_file_path) do
    1 
  end

  defp get_last_change_date(file_path) do
    case File.stat(file_path) do
      {:ok, stat} ->
        {{year, month, day}, _time} = stat.mtime
        Date.new!(year, month, day) |> Date.to_iso8601()
      {:error, _} ->
        "unknown"
    end
  end

  defp analyze_redshift_factors(file_path, age_days, change_count) do
    factors = %{}
    
    factors = if age_days > 365 do
      Map.put(factors, "old_code", 0.3)
    else
      factors
    end
    
    factors = if change_count > 10 do
      Map.put(factors, "frequently_changed", 0.2)
    else
      factors
    end
    
    case File.read(file_path) do
      {:ok, content} ->
        lines = String.split(content, "\n")
        if length(lines) > 200 do
          Map.put(factors, "large_file", 0.2)
        else
          factors
        end
      _ -> factors
    end
  end
end
