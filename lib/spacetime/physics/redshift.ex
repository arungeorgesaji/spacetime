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
end
