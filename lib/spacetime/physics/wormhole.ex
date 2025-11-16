defmodule Spacetime.Physics.Wormhole do
  def wormhole_merge(source_branch, target_branch, options \\ %{}) do
    IO.puts "Creating wormhole between #{source_branch} and #{target_branch}..."
    
    source_history = Spacetime.Repo.Branch.get_branch_history(source_branch)
    target_history = Spacetime.Repo.Branch.get_branch_history(target_branch)
    
    if Enum.empty?(source_history) or Enum.empty?(target_history) do
      {:error, "Both branches need commit history for wormhole merge"}
    else
      analysis = analyze_branches(source_branch, target_branch, source_history, target_history)
      
      feature_flags = generate_feature_flags(analysis, options)
      
      merge_result = perform_smart_merge(source_branch, target_branch, analysis, feature_flags)
      
      bridge_commit = create_wormhole_bridge(merge_result, feature_flags, options)
      
      {:ok, bridge_commit, feature_flags, analysis}
    end
  end

  defp analyze_branches(source_branch, target_branch, source_history, target_history) do
    %{
      source_branch: source_branch,
      target_branch: target_branch,
      source_history: source_history,   
      target_history: target_history,
      source_files: get_branch_files(source_history),
      target_files: get_branch_files(target_history),
      conflicts: find_potential_conflicts(source_history, target_history),
      overlapping_files: find_overlapping_files(source_history, target_history),
      feature_compatibility: assess_feature_compatibility(source_history, target_history)
    }
  end

  defp get_branch_files(commit_history) do
    commit_history
    |> Enum.flat_map(fn %{id: commit_id} ->
      Spacetime.SCM.Internals.get_commit_files(commit_id)
    end)
    |> Enum.uniq()
  end

  defp find_potential_conflicts(source_history, target_history) do
    source_files = get_branch_files(source_history)
    target_files = get_branch_files(target_history)
    
    overlapping = Enum.filter(source_files, &(&1 in target_files))
    
    Enum.flat_map(overlapping, fn file_path ->
      if File.exists?(file_path) do
        analyze_file_for_conflicts(file_path, source_history, target_history)
      else
        []
      end
    end)
  end

  defp analyze_file_for_conflicts(file_path, source_history, target_history) do
    source_content = get_file_in_branch(file_path, source_history)
    target_content = get_file_in_branch(file_path, target_history)
    
    if source_content != target_content do
      conflicts = find_line_level_conflicts(source_content, target_content)
      
      if length(conflicts) > 0 do
        [%{
          file: file_path,
          conflict_count: length(conflicts),
          conflicts: conflicts,
          resolution_strategy: suggest_resolution_strategy(file_path, conflicts)
        }]
      else
        []
      end
    else
      []
    end
  end

  defp get_file_in_branch(file_path, commit_history) do
    latest_commit = Enum.find(commit_history, fn %{id: commit_id} ->
      Spacetime.SCM.Internals.file_in_commit?(commit_id, file_path)
    end)
    
    case latest_commit do
      %{id: _commit_id} ->
        if File.exists?(file_path) do
          File.read!(file_path)
        else
          nil
        end
      _ ->
        nil
    end
  end

  defp find_line_level_conflicts(source_content, target_content) when is_binary(source_content) and is_binary(target_content) do
    source_lines = String.split(source_content, "\n")
    target_lines = String.split(target_content, "\n")
    
    max_lines = max(length(source_lines), length(target_lines))
    
    Enum.with_index(0..(max_lines - 1))
    |> Enum.filter(fn {i, _} ->
      source_line = Enum.at(source_lines, i)
      target_line = Enum.at(target_lines, i)
      
      source_line != target_line and 
      source_line != nil and 
      target_line != nil and
      not is_comment_or_whitespace?(source_line) and
      not is_comment_or_whitespace?(target_line)
    end)
    |> Enum.map(fn {i, _} ->
      %{
        line: i + 1,
        source: Enum.at(source_lines, i),
        target: Enum.at(target_lines, i),
        type: classify_conflict(Enum.at(source_lines, i), Enum.at(target_lines, i))
      }
    end)
  end

  defp find_line_level_conflicts(_, _), do: []

  defp is_comment_or_whitespace?(line) do
    line = String.trim(line)
    line == "" or String.starts_with?(line, ["#", "//", "/*", "*/", "*"])
  end

  defp classify_conflict(source_line, target_line) do
    cond do
      String.contains?(source_line, "def ") and String.contains?(target_line, "def ") -> :function_definition
      String.contains?(source_line, "import ") and String.contains?(target_line, "import ") -> :import
      String.contains?(source_line, "config") and String.contains?(target_line, "config") -> :configuration
      true -> :code_block
    end
  end

  defp suggest_resolution_strategy(_file_path, conflicts) do
    conflict_types = Enum.map(conflicts, & &1.type) |> Enum.uniq()
    
    cond do
      :function_definition in conflict_types -> :feature_flag
      :import in conflict_types -> :merge_both
      :configuration in conflict_types -> :environment_specific
      true -> :manual_resolution
    end
  end

  defp find_overlapping_files(source_history, target_history) do
    source_files = get_branch_files(source_history)
    target_files = get_branch_files(target_history)
    
    Enum.filter(source_files, &(&1 in target_files))
  end

  defp find_shared_dependencies(source_features, target_features) do
    source_deps = MapSet.new(Enum.flat_map(source_features, & &1.dependencies))
    target_deps = MapSet.new(Enum.flat_map(target_features, & &1.dependencies))

    MapSet.intersection(source_deps, target_deps) |> MapSet.to_list()
  end

  defp check_interference(source_features, target_features) do
    source_names = MapSet.new(Enum.flat_map(source_features, & &1.features))
    target_names = MapSet.new(Enum.flat_map(target_features, & &1.features))

    conflicting = MapSet.intersection(source_names, target_names)

    if MapSet.size(conflicting) > 0 do
      {:conflict, MapSet.to_list(conflicting)}
    else
      :ok
    end
  end

  defp assess_feature_compatibility(source_history, target_history) do
    source_features = extract_features(source_history)
    target_features = extract_features(target_history)
    
    %{
      can_coexist: check_feature_coexistence(source_features, target_features),
      shared_dependencies: find_shared_dependencies(source_features, target_features),
      potential_interference: check_interference(source_features, target_features)
    }
  end

  defp extract_features(commit_history) do
    commit_history
    |> Enum.flat_map(fn %{data: commit_data} ->
      message = commit_data.message
      
      features = extract_features_from_message(message)
      dependencies = extract_dependencies_from_message(message)
      
      [%{features: features, dependencies: dependencies}]
    end)
  end

  defp extract_features_from_message(message) do
    patterns = [
      ~r/feat(ure)?:?\s*([^\n]+)/i,
      ~r/add\s+([a-zA-Z0-9_]+)\s+feature/i,
      ~r/implement\s+([a-zA-Z0-9_]+)/i
    ]
    
    Enum.flat_map(patterns, fn pattern ->
      Regex.scan(pattern, message)
      |> Enum.map(fn [_, feature] -> String.trim(feature) end)
    end)
    |> Enum.uniq()
  end

  defp extract_dependencies_from_message(message) do
    patterns = [
      ~r/depends? on:?\s*([^\n]+)/i,
      ~r/requires?:\s*([^\n]+)/i,
      ~r/using\s+([a-zA-Z0-9_]+)/i
    ]
    
    Enum.flat_map(patterns, fn pattern ->
      Regex.scan(pattern, message)
      |> Enum.map(fn [_, dep] -> String.trim(dep) end)
    end)
    |> Enum.uniq()
  end

  defp check_feature_coexistence(source_features, target_features) do
    source_set = MapSet.new(Enum.flat_map(source_features, & &1.features))
    target_set = MapSet.new(Enum.flat_map(target_features, & &1.features))
    
    overlapping = MapSet.intersection(source_set, target_set)
    
    MapSet.size(overlapping) == 0
  end

  defp generate_feature_flags(analysis, options) do
    feature_name = options[:feature_name] || generate_feature_name(analysis.source_branch)
    
    %{
      feature_name: feature_name,
      flag_type: :environment_based,
      environments: options[:environments] || [:dev, :test],
      default_state: options[:default_state] || false,
      conflicts: Enum.map(analysis.conflicts, &generate_flag_for_conflict(&1, feature_name)),
      activation_strategy: options[:activation_strategy] || :gradual_rollout
    }
  end

  defp generate_feature_name(branch_name) do
    branch_name
    |> String.replace(~r/^feature-|^feat-|^f-/, "")
    |> String.replace(~r/[^a-zA-Z0-9]/, "_")
    |> String.downcase()
  end

  defp generate_flag_for_conflict(conflict, feature_name) do
    %{
      file: conflict.file,
      flag_name: "#{feature_name}_#{Path.basename(conflict.file, Path.extname(conflict.file))}",
      strategy: conflict.resolution_strategy,
      lines: Enum.map(conflict.conflicts, & &1.line)
    }
  end

  defp perform_smart_merge(source_branch, target_branch, analysis, feature_flags) do
    IO.puts "Performing smart merge with feature flags..."
    
    merged_files = create_merged_files(analysis, feature_flags)
    
    %{
      source_branch: source_branch,
      target_branch: target_branch,
      merged_files: merged_files,
      feature_flags: feature_flags,
      conflicts_resolved: length(analysis.conflicts),
      strategy: :wormhole_merge
    }
  end

  defp create_merged_files(analysis, feature_flags) do
    Enum.flat_map(analysis.overlapping_files, fn file_path ->
      create_merged_file(file_path, analysis, feature_flags)
    end)
  end

  defp create_merged_file(file_path, analysis, feature_flags) do
    if File.exists?(file_path) do
      source_content = get_file_in_branch(file_path, analysis.source_history)
      target_content = get_file_in_branch(file_path, analysis.target_history)
      
      if source_content && target_content && source_content != target_content do
        merged_content = merge_with_feature_flags(file_path, source_content, target_content, feature_flags)
        
        [%{
          file: file_path,
          original_size: byte_size(source_content),
          merged_size: byte_size(merged_content),
          conflict_count: length(analysis.conflicts),
          content: merged_content
        }]
      else
        []
      end
    else
      []
    end
  end

  defp merge_with_feature_flags(file_path, source_content, target_content, feature_flags) do
    source_lines = String.split(source_content, "\n")
    target_lines = String.split(target_content, "\n")
    
    file_flag = Enum.find(feature_flags.conflicts, &(&1.file == file_path))
    
    if file_flag do
      merged_lines = apply_feature_flag_wrapping(source_lines, target_lines, file_flag)
      Enum.join(merged_lines, "\n")
    else
      source_content
    end
  end

  defp apply_feature_flag_wrapping(source_lines, target_lines, file_flag) do
    flag_name = file_flag.flag_name

    cond do
      file_flag.strategy == :feature_flag ->
        wrap_with_elixir_feature_flag(source_lines, target_lines, flag_name, file_flag.lines)

      file_flag.strategy == :environment_specific ->
        wrap_with_env_check(source_lines, target_lines, flag_name, file_flag)

      true ->
        target_lines
    end
  end

  defp wrap_with_elixir_feature_flag(source_lines, target_lines, flag_name, conflict_lines) do
    lines = Enum.with_index(target_lines, 1)

    Enum.map(lines, fn {line, idx} ->
      if idx in conflict_lines do
        [
          "if FeatureFlags.#{flag_name}_enabled?() do",
          "  #{line}",
          "else",
          "  #{Enum.at(source_lines, idx - 1) || ""}",
          "end"
        ]
      else
        line
      end
    end)
    |> List.flatten()
  end

  defp wrap_with_env_check(source_lines, target_lines, flag_name, file_flag \\ nil) do
    environments = if file_flag, do: file_flag.environments || [:dev, :test], else: [:dev, :test]
    
    [
      "if Application.get_env(:my_app, :env) in #{inspect(environments)} do",
      "  " <> Enum.join(target_lines, "\n  "),
      "else",
      "  " <> Enum.join(source_lines, "\n  "),
      "end"
    ]
    |> Enum.join("\n")
  end

  defp create_wormhole_bridge(merge_result, feature_flags, _options) do
    IO.puts "Creating wormhole bridge commit..."

    flag_config = generate_flag_configuration(feature_flags)

    message = """
    Wormhole Merge: #{merge_result.source_branch} → #{merge_result.target_branch}

    Features preserved with feature flags:
    - #{feature_flags.feature_name}

    Conflicts resolved: #{merge_result.conflicts_resolved}
    Strategy: #{merge_result.strategy}

    Feature flag configuration:
    #{Jason.encode!(flag_config, pretty: true)}

    Use spacetime feature-flags to manage activation.
    """

    commit_id = "wormhole_#{:crypto.strong_rand_bytes(8) |> Base.encode16() |> String.downcase()}"

    IO.puts message
    IO.puts "Bridge commit: #{commit_id}"

    commit_id
  end

  defp generate_flag_configuration(feature_flags) do
    %{
      feature_flags: %{
        feature_flags.feature_name => %{
          description: "Wormhole merge feature flag",
          type: feature_flags.flag_type,
          environments: feature_flags.environments,
          default: feature_flags.default_state,
          activation: feature_flags.activation_strategy
        }
      },
      files_affected: Enum.map(feature_flags.conflicts, & &1.file)
    }
  end

  def can_wormhole_merge?(source_branch, target_branch) do
    source_history = Spacetime.Repo.Branch.get_branch_history(source_branch)
    target_history = Spacetime.Repo.Branch.get_branch_history(target_branch)
    
    if Enum.empty?(source_history) or Enum.empty?(target_history) do
      {:error, "Both branches need commit history"}
    else
      analysis = analyze_branches(source_branch, target_branch, source_history, target_history)
      
      %{
        possible: length(analysis.conflicts) < 10, 
        conflict_count: length(analysis.conflicts),
        compatibility: analysis.feature_compatibility.can_coexist,
        recommendation: generate_recommendation(analysis)
      }
    end
  end

  defp generate_recommendation(analysis) do
    case length(analysis.conflicts) do
      0 -> "Perfect candidate for wormhole merge - no conflicts detected"
      n when n < 5 -> "Good candidate - #{n} conflicts can be handled with feature flags"
      n when n < 10 -> "Moderate - #{n} conflicts may require manual intervention"
      _ -> "Challenging - high conflict count, consider traditional merge"
    end
  end

  def generate_feature_flag_code(feature_name, language \\ :elixir) do
    case language do
      :elixir ->
        """
        # Feature flag for #{feature_name}
        defmodule FeatureFlags do
          def #{feature_name}_enabled? do
            Application.get_env(:my_app, :#{feature_name}, false)
          end
        end
        
        # Usage:
        # if FeatureFlags.#{feature_name}_enabled? do
        #   # New feature code
        # else
        #   # Old feature code  
        # end
        """
      
      :javascript ->
        """
        // Feature flag for #{feature_name}
        const #{feature_name}Enabled = process.env.#{String.upcase(feature_name)}_ENABLED === 'true';
        
        // Usage:
        // if (#{feature_name}Enabled) {
        //   // New feature code
        // } else {
        //   // Old feature code
        // }
        """
      
      _ ->
        "# Feature flag configuration for #{feature_name}"
    end
  end
end
