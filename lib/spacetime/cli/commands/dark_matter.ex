defmodule Spacetime.CLI.Commands.DarkMatter do
  def run do
    IO.puts "Scanning repository for dark matter..."
    IO.puts "Dark matter: Code that exists but has no observable effects"
    IO.puts "=" <> String.duplicate("=", 60)
    
    dark_matter = Spacetime.Physics.DarkMatter.scan_dark_matter()
    
    total_findings = 
      length(dark_matter.dead_functions) +
      length(dark_matter.unused_imports) +
      length(dark_matter.orphaned_configs) +
      length(dark_matter.unused_dependencies) +
      length(dark_matter.unreachable_code)
    
    if total_findings == 0 do
      IO.puts "No dark matter detected! Codebase is clean."
    end
    
    IO.puts "\nDark Matter Report:"
    IO.puts "Total findings: #{total_findings}"
    
    display_findings("Dead Functions", dark_matter.dead_functions, &format_function/1)
    display_findings("Unused Imports", dark_matter.unused_imports, &format_import/1)
    display_findings("Orphaned Configs", dark_matter.orphaned_configs, &format_config/1)
    display_findings("Unused Dependencies", dark_matter.unused_dependencies, &format_dependency/1)
    display_findings("Unreachable Code", dark_matter.unreachable_code, &format_unreachable/1)
    
    calculate_dark_matter_mass(dark_matter)
    
    show_recommendations(dark_matter)
  end

  defp display_findings(title, findings, formatter) when length(findings) > 0 do
    IO.puts "\n#{title} (#{length(findings)}):"
    IO.puts String.duplicate("-", String.length(title) + 10)
    
    findings
    |> Enum.sort_by(& &1.file)
    |> Enum.each(fn finding ->
      IO.puts "  #{formatter.(finding)}"
    end)
  end

  defp display_findings(_title, _findings, _formatter), do: nil

  defp format_function(finding) do
    "#{finding.file}:#{finding.line} - #{finding.function} (dead function)"
  end

  defp format_import(finding) do
    "#{finding.file}:#{finding.line} - #{finding.module} (unused import)"
  end

  defp format_config(finding) do
    "#{finding.file}:#{finding.line} - #{finding.key} (orphaned config)"
  end

  defp format_dependency(finding) do
    "#{finding.file}:#{finding.line} - #{finding.dependency} (unused dependency)"
  end

  defp format_unreachable(finding) do
    "#{finding.file}:#{finding.line} - #{finding.code} (unreachable)"
  end

  defp calculate_dark_matter_mass(dark_matter) do
    mass = 
      length(dark_matter.dead_functions) * 0.5 +
      length(dark_matter.unused_imports) * 0.3 +
      length(dark_matter.orphaned_configs) * 0.2 +
      length(dark_matter.unused_dependencies) * 1.0 +
      length(dark_matter.unreachable_code) * 0.1
    
    IO.puts "\nDark Matter Mass Analysis:"
    IO.puts "Total Mass: #{Float.round(mass, 2)}"
    
    cond do
      mass < 1 -> IO.puts "Impact: Minimal - No significant performance impact"
      mass < 5 -> IO.puts "Impact: Light - Minor build time increase"
      mass < 10 -> IO.puts "Impact: Moderate - Noticeable performance impact"
      mass < 20 -> IO.puts "Impact: Heavy - Significant build and runtime impact"
      true -> IO.puts "Impact: Critical - Major performance degradation"
    end
  end

  defp show_recommendations(dark_matter) do
    IO.puts "\nRecommendations:"
    
    if length(dark_matter.dead_functions) > 0 do
      IO.puts "Remove #{length(dark_matter.dead_functions)} dead functions to reduce code complexity"
    end
    
    if length(dark_matter.unused_imports) > 0 do
      IO.puts "Clean up #{length(dark_matter.unused_imports)} unused imports for faster compilation"
    end
    
    if length(dark_matter.orphaned_configs) > 0 do
      IO.puts "Remove #{length(dark_matter.orphaned_configs)} orphaned config values to simplify configuration"
    end
    
    if length(dark_matter.unused_dependencies) > 0 do
      IO.puts "Remove #{length(dark_matter.unused_dependencies)} unused dependencies to reduce bundle size"
    end
    
    if length(dark_matter.unreachable_code) > 0 do
      IO.puts "Clean up #{length(dark_matter.unreachable_code)} lines of unreachable code"
    end
    
    IO.puts "\nRun 'spacetime dark-matter --cleanup' to automatically remove dark matter"
  end

  def cleanup do
    IO.puts "Cleaning up dark matter..."
    
    dark_matter = Spacetime.Physics.DarkMatter.scan_dark_matter()
    
    cleanup_count = 
      cleanup_dead_functions(dark_matter.dead_functions) +
      cleanup_unused_imports(dark_matter.unused_imports) +
      cleanup_orphaned_configs(dark_matter.orphaned_configs)
    
    IO.puts "Removed #{cleanup_count} dark matter items"
    
    if length(dark_matter.unused_dependencies) > 0 do
      IO.puts "\nUnused dependencies found:"
      Enum.each(dark_matter.unused_dependencies, fn dep ->
        IO.puts "   - #{dep.dependency} in #{dep.file}:#{dep.line}"
      end)
      IO.puts "Manually remove these from your dependency files"
    end
  end

  defp cleanup_dead_functions(dead_functions) do
    dead_functions
    |> Enum.group_by(& &1.file)
    |> Enum.map(fn {file, functions} ->
      remove_functions_from_file(file, functions)
    end)
    |> Enum.sum()
  end

  defp remove_functions_from_file(file_path, functions) do
    if File.exists?(file_path) do
      lines = File.read!(file_path) |> String.split("\n")
      
      lines_to_remove = Enum.flat_map(functions, fn func ->
        find_function_body_lines(lines, func.line)
      end)
      |> Enum.uniq()
      |> Enum.sort()
      
      if length(lines_to_remove) > 0 do
        new_lines = remove_lines(lines, lines_to_remove)
        File.write!(file_path, Enum.join(new_lines, "\n"))
        IO.puts "Removed #{length(lines_to_remove)} lines from #{file_path}"
        length(lines_to_remove)
      else
        0
      end
    else
      0
    end
  end

  defp find_function_body_lines(lines, start_line) do
    end_line = min(start_line + 10, length(lines))
    
    start_line..end_line
    |> Enum.to_list()
    |> Enum.filter(fn line_num ->
      line_num <= length(lines) and 
      not String.match?(Enum.at(lines, line_num - 1), ~r/^\s*(def|function|class)\s+/)
    end)
  end

  defp remove_lines(lines, line_numbers_to_remove) do
    Enum.with_index(lines, 1)
    |> Enum.filter(fn {_line, line_num} ->
      not (line_num in line_numbers_to_remove)
    end)
    |> Enum.map(&elem(&1, 0))
  end

  defp cleanup_unused_imports(unused_imports) do
    unused_imports
    |> Enum.group_by(& &1.file)
    |> Enum.map(fn {file, imports} ->
      remove_imports_from_file(file, imports)
    end)
    |> Enum.sum()
  end

  defp remove_imports_from_file(file_path, imports) do
    if File.exists?(file_path) do
      lines = File.read!(file_path) |> String.split("\n")
      
      lines_to_remove = Enum.map(imports, & &1.line)
      new_lines = remove_lines(lines, lines_to_remove)
      
      File.write!(file_path, Enum.join(new_lines, "\n"))
      IO.puts "Removed #{length(imports)} imports from #{file_path}"
      length(imports)
    else
      0
    end
  end

  defp cleanup_orphaned_configs(orphaned_configs) do
    orphaned_configs
    |> Enum.group_by(& &1.file)
    |> Enum.map(fn {file, configs} ->
      remove_configs_from_file(file, configs)
    end)
    |> Enum.sum()
  end

  defp remove_configs_from_file(file_path, configs) do
    if File.exists?(file_path) do
      lines = File.read!(file_path) |> String.split("\n")
      
      lines_to_remove = Enum.map(configs, & &1.line)
      new_lines = remove_lines(lines, lines_to_remove)
      
      File.write!(file_path, Enum.join(new_lines, "\n"))
      IO.puts "Removed #{length(configs)} configs from #{file_path}"
      length(configs)
    else
      0
    end
  end
end
