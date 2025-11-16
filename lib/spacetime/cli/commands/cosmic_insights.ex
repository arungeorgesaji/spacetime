defmodule Spacetime.CLI.Commands.CosmicInsights do
  alias Spacetime.Physics.Gravity
  alias Spacetime.Physics.Redshift
  alias Spacetime.Physics.Quantum
  alias Spacetime.CLI.Commands.{GravityVisualization, RedshiftVisualization}

  def run(options \\ %{}) do
    IO.puts("Cosmic Insights")
    IO.puts("=" <> String.duplicate("=", 60))
    
    insights = gather_cosmic_insights(options)
    
    if options.json do
      json_insights(insights)
    else
      render_insights(insights, options)
    end
  end

  defp gather_cosmic_insights(options) do
    %{
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      repository: analyze_repository_state(),
      gravity: analyze_gravity_physics(),
      redshift: analyze_redshift_physics(),
      quantum: analyze_quantum_physics(),
      recommendations: generate_recommendations(),
      cosmic_health: calculate_cosmic_health_score()
    }
  end

  defp analyze_repository_state do
    branches = Spacetime.Repo.Branch.list_branches()
    current_branch = Spacetime.Repo.Branch.get_current_branch()
    object_count = count_objects()
    
    %{
      branch_count: length(branches),
      current_branch: current_branch,
      total_objects: object_count,
      has_commits: object_count > 0,
      active_branches: Enum.filter(branches, &(Spacetime.Repo.Branch.get_branch_commit(&1) != ""))
    }
  end

  defp analyze_gravity_physics do
    branches = Spacetime.Repo.Branch.list_branches()
    
    gravitational_data = Enum.map(branches, fn branch ->
      history = Spacetime.Repo.Branch.get_branch_history(branch)
      mass_data = Gravity.calculate_branch_mass(branch, history)
      
      %{
        branch: branch,
        mass: mass_data.total,
        commit_count: length(history),
        is_heavy: mass_data.total > 10.0
      }
    end)
    
    total_mass = Enum.reduce(gravitational_data, 0, &(&2 + &1.mass))
    heaviest_branch = gravitational_data |> Enum.max_by(& &1.mass)
    
    %{
      total_repository_mass: total_mass,
      average_branch_mass: if(length(gravitational_data) > 0, do: total_mass / length(gravitational_data), else: 0),
      heaviest_branch: %{
        name: heaviest_branch.branch,
        mass: heaviest_branch.mass
      },
      gravitational_center: Gravity.find_gravitational_center(),
      branch_count: length(gravitational_data)
    }
  end

  defp analyze_redshift_physics do
    redshift_data = Redshift.analyze_repository_redshift()
    summary = redshift_data.summary
    
    %{
      average_redshift: summary.average_redshift,
      critical_files: summary.distribution.critical,
      total_files: summary.total_files,
      health_score: calculate_redshift_health_score(summary),
      trend: analyze_redshift_trend(redshift_data.files),
      most_redshifted:
        summary.most_redshifted
        |> Enum.take(3)
        |> Enum.map(fn {path, redshift} ->
          %{
            path: path,
            redshift: redshift
          }
        end)
    }
  end

  defp analyze_quantum_physics do
    entanglements = Quantum.list_entanglements()
    
    %{
      active_entanglements: length(entanglements),
      bidirectional_count: Enum.count(entanglements, & &1.bidirectional),
      total_syncs: Enum.reduce(entanglements, 0, &(&2 + &1.sync_count)),
      recent_entanglements: Enum.filter(entanglements, &is_recent_entanglement/1)
    }
  end

  defp calculate_redshift_health_score(summary) do
    max_score = 100
    penalty = summary.average_redshift * 50
    critical_penalty = summary.distribution.critical * 10
    
    health = max_score - penalty - critical_penalty
    max(0, health)
  end

  defp analyze_redshift_trend(files) do
    recent_files = Enum.filter(files, &(&1.age_days <= 30))
    old_files = Enum.filter(files, &(&1.age_days > 180))
    
    recent_avg = if length(recent_files) > 0 do
      Enum.reduce(recent_files, 0, &(&2 + &1.redshift)) / length(recent_files)
    else
      0
    end
    
    old_avg = if length(old_files) > 0 do
      Enum.reduce(old_files, 0, &(&2 + &1.redshift)) / length(old_files)
    else
      0
    end
    
    cond do
      recent_avg < old_avg -> "improving"
      recent_avg > old_avg -> "worsening"
      true -> "stable"
    end
  end

  defp is_recent_entanglement(entanglement) do
    case DateTime.from_iso8601(entanglement.created_at) do
      {:ok, dt, _} ->
        days_ago = DateTime.diff(DateTime.utc_now(), dt, :day)
        days_ago <= 7
      _ -> false
    end
  end

  defp calculate_cosmic_health_score do
    redshift_data = Redshift.analyze_repository_redshift()
    redshift_health = calculate_redshift_health_score(redshift_data.summary)
    
    branches = Spacetime.Repo.Branch.list_branches()
    gravitational_data = Enum.map(branches, fn branch ->
      history = Spacetime.Repo.Branch.get_branch_history(branch)
      Gravity.calculate_branch_mass(branch, history).total
    end)
    
    avg_mass = if length(gravitational_data) > 0 do
      Enum.sum(gravitational_data) / length(gravitational_data)
    else
      0
    end
    
    gravity_health = if avg_mass > 20, do: 50, else: 80
    
    entanglements = Quantum.list_entanglements()
    quantum_health = if length(entanglements) > 5, do: 70, else: 90
    
    total_health = (redshift_health + gravity_health + quantum_health) / 3
    Float.round(total_health, 1)
  end

  defp generate_recommendations do
    recommendations = []
    
    branches = Spacetime.Repo.Branch.list_branches()
    gravitational_data = Enum.map(branches, fn branch ->
      history = Spacetime.Repo.Branch.get_branch_history(branch)
      mass_data = Gravity.calculate_branch_mass(branch, history)
      %{branch: branch, mass: mass_data.total, history: history}
    end)
    
    heavy_branches = Enum.filter(gravitational_data, & &1.mass > 15.0)
    if length(heavy_branches) > 0 do
      recommendations = recommendations ++ [
        %{
          type: "gravity",
          priority: "high",
          message: "Consider merging heavy branches to reduce gravitational debt",
          details: Enum.map(heavy_branches, & &1.branch)
        }
      ]
    end
    
    redshift_data = Redshift.analyze_repository_redshift()
    if redshift_data.summary.distribution.critical > 0 do
      recommendations = recommendations ++ [
        %{
          type: "redshift",
          priority: "high", 
          message: "Refactor critical redshift files to improve readability",
          details: "Run 'spacetime redshift-viz --threshold=0.8' to see files"
        }
      ]
    end
    
    entanglements = Quantum.list_entanglements()
    if length(entanglements) == 0 do
      recommendations = recommendations ++ [
        %{
          type: "quantum",
          priority: "low",
          message: "Consider using quantum entanglement for related branches",
          details: "Use 'spacetime quantum-entangle' to sync changes"
        }
      ]
    end
    
    recommendations
  end

  defp count_objects do
    objects_dir = ".spacetime/objects"
    
    if File.exists?(objects_dir) do
      objects_dir
      |> File.ls!()
      |> Enum.filter(fn dir -> String.length(dir) == 2 end)
      |> Enum.flat_map(fn dir ->
        Path.join([objects_dir, dir])
        |> File.ls!()
      end)
      |> Enum.count()
    else
      0
    end
  end

  defp render_insights(insights, options) do
    IO.puts("\nRepository Overview")
    IO.puts(String.duplicate("-", 40))
    IO.puts("Branches: #{insights.repository.branch_count}")
    IO.puts("Current: #{insights.repository.current_branch}")
    IO.puts("Objects: #{insights.repository.total_objects}")
    
    IO.puts("\nCosmic Health Score: #{insights.cosmic_health}/100")
    render_health_bar(insights.cosmic_health)
    
    IO.puts("\nGravity Analysis")
    IO.puts(String.duplicate("-", 40))
    IO.puts("Total Mass: #{:erlang.float_to_binary(insights.gravity.total_repository_mass, decimals: 2)}")
    IO.puts("Average Branch Mass: #{:erlang.float_to_binary(insights.gravity.average_branch_mass, decimals: 2)}")
    IO.puts("Heaviest Branch: #{insights.gravity.heaviest_branch.name} (#{:erlang.float_to_binary(insights.gravity.heaviest_branch.mass, decimals: 2)})")
    
    IO.puts("\nRedshift Analysis")
    IO.puts(String.duplicate("-", 40))
    IO.puts("Average Redshift: #{:erlang.float_to_binary(insights.redshift.average_redshift, decimals: 3)}")
    IO.puts("Critical Files: #{insights.redshift.critical_files}")
    IO.puts("Health: #{insights.redshift.health_score}/100")
    IO.puts("Trend: #{insights.redshift.trend}")
    
    IO.puts("\nQuantum Analysis") 
    IO.puts(String.duplicate("-", 40))
    IO.puts("Active Entanglements: #{insights.quantum.active_entanglements}")
    IO.puts("Bidirectional: #{insights.quantum.bidirectional_count}")
    IO.puts("Total Syncs: #{insights.quantum.total_syncs}")
    
    render_recommendations_section(insights.recommendations)
    
    if options.detailed do
      render_detailed_insights(insights)
    end
    
    render_next_steps(insights)
  end

  defp render_health_bar(score) do
    bar_length = trunc(score / 5)
    bar = String.duplicate("█", bar_length) <> String.duplicate("░", 20 - bar_length)
    
    IO.puts("#{bar} #{score}%")
  end

  defp render_recommendations_section(recommendations) do
    if length(recommendations) > 0 do
      IO.puts("\nCosmic Recommendations")
      IO.puts(String.duplicate("-", 40))

      Enum.each(recommendations, fn rec ->
        IO.puts("#{rec.message}")

        cond do
          is_list(rec.details) ->
            Enum.each(rec.details, fn detail ->
              IO.puts("   - #{detail}")
            end)

          is_binary(rec.details) ->
            IO.puts("   #{rec.details}")

          true ->
            :ok
        end
      end)

    else
      IO.puts("\nNo critical recommendations - your cosmos is healthy!")
    end
  end

  defp render_detailed_insights(insights) do
    IO.puts("\nDetailed Analysis")
    IO.puts(String.duplicate("=", 50))
    
    if length(insights.redshift.most_redshifted) > 0 do
      IO.puts("\nMost Redshifted Files:")
      Enum.each(insights.redshift.most_redshifted, fn {path, redshift} ->
        IO.puts("   - #{path} (#{:erlang.float_to_binary(redshift, decimals: 3)})")
      end)
    end
    
    IO.puts("\nActive Branches:")
    Enum.each(insights.repository.active_branches, fn branch ->
      IO.puts("   - #{branch}")
    end)
  end

  defp render_detailed_insights(insights) do
    IO.puts("\nDetailed Analysis")
    IO.puts(String.duplicate("=", 50))
    
    if length(insights.redshift.most_redshifted) > 0 do
      IO.puts("\nMost Redshifted Files:")
      Enum.each(insights.redshift.most_redshifted, fn {path, redshift} ->
        IO.puts("   - #{path} (#{:erlang.float_to_binary(redshift, decimals: 3)})")
      end)
    end
    
    IO.puts("\nActive Branches:")
    Enum.each(insights.repository.active_branches, fn branch ->
      IO.puts("   - #{branch}")
    end)
  end

  defp render_next_steps(insights) do
    IO.puts("\nNext Steps")
    IO.puts(String.duplicate("-", 40))
    
    if insights.redshift.critical_files > 0 do
      IO.puts("Run 'spacetime redshift-viz' to see critical files")
    end
    
    if insights.gravity.total_repository_mass > 50 do
      IO.puts("Run 'spacetime gravity-viz' to analyze branch relationships")
    end
    
    if insights.quantum.active_entanglements == 0 do
      IO.puts("Run 'spacetime quantum-status' to manage entanglements")
    end
    
    IO.puts("Run 'spacetime cosmic-insights --detailed' for more analysis")
    IO.puts("Run 'spacetime cosmic-insights --json' to get json data")
  end

  defp json_insights(insights) do
    json_data = %{
      cosmic_insights: insights,
      generated_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      version: "1.0"
    }
    
    IO.puts(Jason.encode!(json_data, pretty: true))
  end
end
