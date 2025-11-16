defmodule Spacetime.CLI.Commands.RedshiftVisualization do
  alias Spacetime.Physics.Redshift

  def run(options \\ %{}) do
    IO.puts("Spacetime Redshift Analysis")
    IO.puts("=" <> String.duplicate("=", 50))
    
    redshift_data = Redshift.analyze_repository_redshift(options)
    
    format = Map.get(options, :format, "text")
    
    case format do
      "text" -> render_text(redshift_data, options)
      "timeline" -> render_timeline(redshift_data, options)
      "json" -> render_json(redshift_data, options)
      _ -> render_text(redshift_data, options)
    end
  end

  defp render_text(redshift_data, options) do
    files_data = redshift_data.files
    summary = redshift_data.summary
    
    IO.puts("\nFile Redshift Analysis")
    IO.puts(String.duplicate("-", 80))
    
    sorted_files = Enum.sort_by(files_data, & -&1.redshift)
    
    threshold = Map.get(options, :threshold, 0.7)
    show_improvements = Map.get(options, :show_improvements, false)
    
    Enum.each(sorted_files, fn file_data ->
      if file_data.redshift >= threshold or 
         (show_improvements and file_data.redshift < 0) do
        
        render_file_analysis(file_data)
      end
    end)
    
    render_redshift_summary(summary, options)
    
    render_recommendations(sorted_files, summary)
  end

  defp render_file_analysis(file_data) do
    redshift_str = :erlang.float_to_binary(file_data.redshift, decimals: 3)
    age_days = file_data.age_days
    change_count = file_data.change_count
    
    indicator = cond do
      file_data.redshift >= 0.8 -> "!!!"
      file_data.redshift >= 0.6 -> "!!" 
      file_data.redshift >= 0.4 -> "!"
      file_data.redshift >= 0.2 -> "."
      file_data.redshift < 0 -> "+"
      true -> "-"
    end
    
    IO.puts("#{indicator} #{file_data.path}")
    IO.puts("   Redshift: #{redshift_str} | Age: #{age_days} days | Changes: #{change_count}")
    
    if map_size(file_data.factors) > 0 do
      IO.puts("   Factors:")
      Enum.each(file_data.factors, fn {factor, impact} ->
        impact_str = :erlang.float_to_binary(impact, decimals: 2)
        IO.puts("     - #{factor}: #{impact_str}")
      end)
    end
    
    if file_data.last_change do
      IO.puts("   Last change: #{file_data.last_change}")
    end
    
    IO.puts("")
  end

  defp render_redshift_summary(summary, options) do
    IO.puts("\nRepository Redshift Summary")
    IO.puts(String.duplicate("-", 40))
    
    IO.puts("Total files analyzed: #{summary.total_files}")
    IO.puts("Average redshift: #{:erlang.float_to_binary(summary.average_redshift, decimals: 3)}")
    IO.puts("Max redshift: #{:erlang.float_to_binary(summary.max_redshift, decimals: 3)}")
    IO.puts("Min redshift: #{:erlang.float_to_binary(summary.min_redshift, decimals: 3)}")
    
    IO.puts("\nRedshift Distribution:")
    IO.puts("  Critical (≥0.8): #{summary.distribution.critical}")
    IO.puts("  High (0.6-0.8): #{summary.distribution.high}") 
    IO.puts("  Medium (0.4-0.6): #{summary.distribution.medium}")
    IO.puts("  Low (0.2-0.4): #{summary.distribution.low}")
    IO.puts("  Minimal (<0.2): #{summary.distribution.minimal}")
    
    show_improvements = Map.get(options, :show_improvements, false)
    
    if show_improvements and summary.distribution.blueshift > 0 do
      IO.puts("  Blueshift (improved): #{summary.distribution.blueshift}")
    end
    
    if summary.most_redshifted != [] do
      IO.puts("\nMost Redshifted Files:")
      Enum.each(summary.most_redshifted, fn {path, redshift} ->
        redshift_str = :erlang.float_to_binary(redshift, decimals: 3)
        IO.puts("  - #{path} (#{redshift_str})")
      end)
    end
  end

  defp render_recommendations(files, summary) do
    critical_files = Enum.filter(files, & &1.redshift >= 0.8)
    old_files = Enum.filter(files, & &1.age_days > 365) 
    
    IO.puts("\nRecommendations:")
    
    if length(critical_files) > 0 do
      IO.puts("Refactor critical files (#{length(critical_files)} files):")
      Enum.each(critical_files, fn file ->
        IO.puts("   - #{file.path} (redshift: #{:erlang.float_to_binary(file.redshift, decimals: 2)})")
      end)
    end
    
    if length(old_files) > 0 do
      IO.puts("Review ancient files (#{length(old_files)} files older than 1 year):")
      Enum.each(Enum.take(old_files, 5), fn file -> 
        IO.puts("   - #{file.path} (#{file.age_days} days old)")
      end)
    end
    
    if summary.average_redshift > 0.6 do
      IO.puts("Overall repository redshift is high - consider modernization effort")
    end
    
    if summary.distribution.blueshift > 0 do
      IO.puts("#{summary.distribution.blueshift} files improved recently - good work!")
    end
  end

  defp group_files_by_directory(files) do
    Enum.group_by(files, fn file_data ->
      Path.dirname(file_data.path)
    end)
  end

  defp render_timeline(redshift_data, _options) do
    IO.puts("\nRedshift Timeline")
    IO.puts("Showing how code redshift has evolved over time")
    IO.puts(String.duplicate("=", 70))
    
    timeline_data = calculate_timeline_data(redshift_data.files)
    
    IO.puts("\nRedshift Evolution:")
    
    Enum.each(timeline_data, fn {period, data} ->
      avg_redshift = :erlang.float_to_binary(data.avg_redshift, decimals: 3)
      file_count = data.file_count
      
      bar_length = trunc(data.avg_redshift * 20)
      bar = String.duplicate("█", bar_length) |> String.pad_trailing(20)
      
      IO.puts("#{period}: #{bar} #{avg_redshift} (#{file_count} files)")
    end)
    
    trend = calculate_redshift_trend(timeline_data)
    IO.puts("\nOverall Trend: #{trend}")
    
    if trend == "worsening" do
      IO.puts("Recommendation: Focus on reducing technical debt")
    else
      IO.puts("Good work! Codebase health is stable or improving")
    end
  end

  defp calculate_timeline_data(files) do
    ranges = [
      {"Last week", 0..7},
      {"1-4 weeks", 8..30},
      {"1-6 months", 31..180},
      {"6-12 months", 181..365},
      {"Over 1 year", 366..9999}
    ]
    
    Enum.map(ranges, fn {label, days_range} ->
      period_files = Enum.filter(files, fn file ->
        file.age_days in days_range
      end)
      
      avg_redshift = if length(period_files) > 0 do
        Enum.reduce(period_files, 0, &(&2 + &1.redshift)) / length(period_files)
      else
        0.0
      end
      
      {label, %{avg_redshift: avg_redshift, file_count: length(period_files)}}
    end)
    |> Enum.filter(fn {_, data} -> data.file_count > 0 end)
  end

  defp calculate_redshift_trend(timeline_data) do
    recent = Enum.find(timeline_data, fn {label, _} -> label == "Last week" end)
    old = Enum.find(timeline_data, fn {label, _} -> label == "Over 1 year" end)
    
    cond do
      !recent or !old -> "unknown"
      elem(recent, 1).avg_redshift > elem(old, 1).avg_redshift -> "worsening"
      elem(recent, 1).avg_redshift < elem(old, 1).avg_redshift -> "improving"
      true -> "stable"
    end
  end

  defp render_json(redshift_data, _options) do
    json_data = %{
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      analysis: %{
        files: Enum.map(redshift_data.files, fn file ->
          Map.take(file, [:path, :redshift, :age_days, :change_count, :factors])
        end),
        summary: %{
          total_files: redshift_data.summary.total_files,
          average_redshift: redshift_data.summary.average_redshift,
          max_redshift: redshift_data.summary.max_redshift,
          min_redshift: redshift_data.summary.min_redshift,
          distribution: redshift_data.summary.distribution,
          most_redshifted: Enum.map(redshift_data.summary.most_redshifted, fn {path, redshift} ->
            %{path: path, redshift: redshift}
          end)
        },
        recommendations: generate_json_recommendations(redshift_data)
      }
    }
    
    IO.puts(Jason.encode!(json_data, pretty: true))
  end

  defp generate_json_recommendations(redshift_data) do
    critical_files = Enum.filter(redshift_data.files, & &1.redshift >= 0.8)
    old_files = Enum.filter(redshift_data.files, & &1.age_days > 365)
    
    %{
      refactor_critical: Enum.map(critical_files, & &1.path),
      review_old: Enum.map(old_files, & &1.path),
      overall_health: if(redshift_data.summary.average_redshift > 0.6, do: "poor", else: "good")
    }
  end
end
