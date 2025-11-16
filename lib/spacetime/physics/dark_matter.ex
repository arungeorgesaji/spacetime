defmodule Spacetime.Physics.DarkMatter do
  def scan_dark_matter(specific_files \\ nil) do
    IO.puts "Scanning for dark matter..."
    
    %{
      dead_functions: find_dead_functions(specific_files),
      unused_imports: find_unused_imports(specific_files),
      orphaned_configs: find_orphaned_configs(specific_files),
      unused_dependencies: find_unused_dependencies(specific_files),
      unreachable_code: find_unreachable_code(specific_files)
    }
  end

  def find_dead_functions(specific_files \\ nil) do
    code_files = get_code_files(specific_files)
    
    Enum.flat_map(code_files, fn file_path ->
      find_dead_functions_in_file(file_path)
    end)
    |> Enum.uniq()
  end

  defp find_dead_functions_in_file(file_path) do
    if File.exists?(file_path) do
      content = File.read!(file_path)
      defined_functions = extract_defined_functions(content, file_path)
      called_functions = extract_called_functions(content)
      
      Enum.filter(defined_functions, fn {func_name, _line} ->
        not Enum.any?(called_functions, &String.contains?(&1, func_name))
      end)
      |> Enum.map(fn {func_name, line} -> 
        %{file: file_path, function: func_name, line: line, type: :dead_function}
      end)
    else
      []
    end
  end

  defp extract_defined_functions(content, file_path) do
    case Path.extname(file_path) do
      ".ex" -> extract_elixir_functions(content)
      ".exs" -> extract_elixir_functions(content)
      ".js" -> extract_javascript_functions(content)
      ".ts" -> extract_typescript_functions(content)
      ".py" -> extract_python_functions(content)
      ".rb" -> extract_ruby_functions(content)
      ".java" -> extract_java_functions(content)
      _ -> []
    end
  end

  defp extract_elixir_functions(content) do
    patterns = [
      ~r/def\s+([a-zA-Z0-9_?!]+)/,
      ~r/defp\s+([a-zA-Z0-9_?!]+)/,
      ~r/defmacro\s+([a-zA-Z0-9_?!]+)/
    ]
    
    lines = String.split(content, "\n")
    
    Enum.with_index(lines, 1)
    |> Enum.flat_map(fn {line, line_number} ->
      Enum.flat_map(patterns, fn pattern ->
        Regex.scan(pattern, line)
        |> Enum.map(fn [_, func_name] -> {func_name, line_number} end)
      end)
    end)
  end

  defp extract_javascript_functions(content) do
    patterns = [
      ~r/function\s+([a-zA-Z0-9_$]+)/,
      ~r/const\s+([a-zA-Z0-9_$]+)\s*=\s*\([^)]*\)\s*=>/,
      ~r/let\s+([a-zA-Z0-9_$]+)\s*=\s*\([^)]*\)\s*=>/,
      ~r/var\s+([a-zA-Z0-9_$]+)\s*=\s*\([^)]*\)\s*=>/
    ]
    
    lines = String.split(content, "\n")
    
    Enum.with_index(lines, 1)
    |> Enum.flat_map(fn {line, line_number} ->
      Enum.flat_map(patterns, fn pattern ->
        Regex.scan(pattern, line)
        |> Enum.map(fn [_, func_name] -> {func_name, line_number} end)
      end)
    end)
  end

  defp extract_called_functions(content) do
    patterns = [
      ~r/([a-zA-Z0-9_?!]+)\(/,
      ~r/\.([a-zA-Z0-9_?!]+)\(/,
      ~r/@([a-zA-Z0-9_?!]+)\./
    ]
    
    Enum.flat_map(patterns, fn pattern ->
      Regex.scan(pattern, content)
      |> Enum.map(fn [_, func_name] -> func_name end)
    end)
    |> Enum.uniq()
  end

  def find_unused_imports(specific_files \\ nil) do
    code_files = get_code_files(specific_files)
    
    Enum.flat_map(code_files, fn file_path ->
      find_unused_imports_in_file(file_path)
    end)
    |> Enum.uniq()
  end

  defp find_unused_imports_in_file(file_path) do
    if File.exists?(file_path) do
      content = File.read!(file_path)
      imports = extract_imports(content, file_path)
      used_modules = extract_used_modules(content)
      
      Enum.filter(imports, fn {module, _line} ->
        not Enum.any?(used_modules, &String.contains?(&1, module))
      end)
      |> Enum.map(fn {module, line} ->
        %{file: file_path, module: module, line: line, type: :unused_import}
      end)
    else
      []
    end
  end

  defp extract_imports(content, file_path) do
    case Path.extname(file_path) do
      ".ex" -> extract_elixir_imports(content)
      ".exs" -> extract_elixir_imports(content)
      ".js" -> extract_javascript_imports(content)
      ".ts" -> extract_typescript_imports(content)
      _ -> []
    end
  end

  defp extract_elixir_imports(content) do
    patterns = [
      ~r/import\s+([a-zA-Z0-9_.]+)/,
      ~r/require\s+([a-zA-Z0-9_.]+)/,
      ~r/use\s+([a-zA-Z0-9_.]+)/,
      ~r/alias\s+([a-zA-Z0-9_.]+)/
    ]
    
    lines = String.split(content, "\n")
    
    Enum.with_index(lines, 1)
    |> Enum.flat_map(fn {line, line_number} ->
      Enum.flat_map(patterns, fn pattern ->
        Regex.scan(pattern, line)
        |> Enum.map(fn [_, module] -> {module, line_number} end)
      end)
    end)
  end

  defp extract_used_modules(content) do
    patterns = [
      ~r/([A-Z][a-zA-Z0-9_]*)\./,
      ~r/@([a-zA-Z0-9_]+)\./
    ]
    
    Enum.flat_map(patterns, fn pattern ->
      Regex.scan(pattern, content)
      |> Enum.map(fn [_, module] -> module end)
    end)
    |> Enum.uniq()
  end

  def find_orphaned_configs(specific_files \\ nil) do
    config_files = get_config_files(specific_files)
    
    Enum.flat_map(config_files, fn file_path ->
      find_orphaned_configs_in_file(file_path)
    end)
    |> Enum.uniq()
  end

  defp find_orphaned_configs_in_file(file_path) do
    if File.exists?(file_path) do
      content = File.read!(file_path)
      config_keys = extract_config_keys(content, file_path)
      
      Enum.filter(config_keys, fn {key, line} ->
        not is_config_key_used?(key, file_path)
      end)
      |> Enum.map(fn {key, line} ->
        %{file: file_path, key: key, line: line, type: :orphaned_config}
      end)
    else
      []
    end
  end

  defp extract_config_keys(content, file_path) do
    case Path.extname(file_path) do
      ".exs" -> extract_elixir_config_keys(content)
      ".json" -> extract_json_config_keys(content)
      ".yml" -> extract_yaml_config_keys(content)
      ".yaml" -> extract_yaml_config_keys(content)
      _ -> []
    end
  end

  defp extract_elixir_config_keys(content) do
    pattern = ~r/config\s+:([a-zA-Z0-9_]+),/
    
    lines = String.split(content, "\n")
    
    Enum.with_index(lines, 1)
    |> Enum.flat_map(fn {line, line_number} ->
      Regex.scan(pattern, line)
      |> Enum.map(fn [_, key] -> {key, line_number} end)
    end)
  end

  defp is_config_key_used?(key, _config_file_path) do
    code_files = find_code_files()
    
    Enum.any?(code_files, fn code_file ->
      if File.exists?(code_file) do
        content = File.read!(code_file)
        patterns = [
          ~r/Application\.get_env\([^,]+,\s*:#{key}\)/,
          ~r/System\.get_env\(["']#{key}["']\)/,
          ~r/config\[["']#{key}["']\]/
        ]
        
        Enum.any?(patterns, &Regex.match?(&1, content))
      else
        false
      end
    end)
  end

  def find_unused_dependencies(specific_files \\ nil) do
    dependency_files = get_dependency_files(specific_files)
    
    Enum.flat_map(dependency_files, fn file_path ->
      find_unused_dependencies_in_file(file_path)
    end)
    |> Enum.uniq()
  end

  defp find_unused_dependencies_in_file(file_path) do
    case Path.basename(file_path) do
      "mix.exs" -> find_unused_mix_dependencies(file_path)
      "package.json" -> find_unused_npm_dependencies(file_path)
      _ -> []
    end
  end

  defp find_unused_mix_dependencies(file_path) do
    if File.exists?(file_path) do
      content = File.read!(file_path)
      dependencies = extract_mix_dependencies(content)
      
      Enum.filter(dependencies, fn {dep, _line} ->
        not is_dependency_used?(dep, file_path)
      end)
      |> Enum.map(fn {dep, line} ->
        %{file: file_path, dependency: dep, line: line, type: :unused_dependency}
      end)
    else
      []
    end
  end

  defp extract_mix_dependencies(content) do
    pattern = ~r/\{:\s*([a-zA-Z0-9_]+)\s*,/
    
    lines = String.split(content, "\n")
    
    Enum.with_index(lines, 1)
    |> Enum.flat_map(fn {line, line_number} ->
      Regex.scan(pattern, line)
      |> Enum.map(fn [_, dep] -> {dep, line_number} end)
    end)
  end

  defp is_dependency_used?(dependency, _file_path) do
    code_files = find_code_files()
    
    Enum.any?(code_files, fn code_file ->
      if File.exists?(code_file) do
        content = File.read!(code_file)
        patterns = [
          ~r/import\s+#{dependency}/,
          ~r/require\s+#{dependency}/,
          ~r/use\s+#{dependency}/,
          ~r/#{dependency}\./
        ]
        
        Enum.any?(patterns, &Regex.match?(&1, content))
      else
        false
      end
    end)
  end

  def find_unreachable_code(specific_files \\ nil) do
    code_files = get_code_files(specific_files)
    
    Enum.flat_map(code_files, fn file_path ->
      find_unreachable_code_in_file(file_path)
    end)
    |> Enum.uniq()
  end

  defp find_unreachable_code_in_file(file_path) do
    if File.exists?(file_path) do
      content = File.read!(file_path)
      lines = String.split(content, "\n")
      
      Enum.with_index(lines, 1)
      |> Enum.filter(fn {line, line_number} ->
        is_unreachable_line?(line, line_number, lines)
      end)
      |> Enum.map(fn {line, line_number} ->
        %{file: file_path, code: String.trim(line), line: line_number, type: :unreachable_code}
      end)
    else
      []
    end
  end

  defp is_unreachable_line?(_line, line_number, all_lines) do
    previous_lines = Enum.take(all_lines, line_number - 1)
    
    Enum.any?(previous_lines, fn prev_line ->
      String.contains?(prev_line, ["return", "raise", "throw", "exit"]) and
      not String.contains?(prev_line, ["def", "function", "class"])  
    end)
  end

  defp get_code_files(nil) do
    find_code_files()
  end

  defp get_code_files(specific_files) do
    specific_files
    |> Enum.filter(&File.regular?/1)
    |> Enum.filter(fn file ->
      ext = Path.extname(file)
      ext in [".ex", ".exs", ".js", ".ts", ".py", ".rb", ".java", ".go", ".rs", ".cpp", ".c", ".h"]
    end)
  end

  defp get_config_files(nil) do
    find_config_files()
  end

  defp get_config_files(specific_files) do
    specific_files
    |> Enum.filter(&File.regular?/1)
    |> Enum.filter(fn file ->
      ext = Path.extname(file)
      ext in [".exs", ".json", ".yml", ".yaml", ".config", ".env"]
    end)
  end

  defp get_dependency_files(nil) do
    find_dependency_files()
  end

  defp get_dependency_files(specific_files) do
    specific_files
    |> Enum.filter(&File.exists?/1)
    |> Enum.filter(fn file ->
      basename = Path.basename(file)
      basename in ["mix.exs", "package.json", "requirements.txt", "Cargo.toml", "pom.xml", "build.gradle"]
    end)
  end

  defp find_code_files do
    Path.wildcard("**/*.{ex,exs,js,ts,py,rb,java,go,rs,cpp,c,h}")
    |> Enum.filter(&File.regular?/1)
  end

  defp find_config_files do
    Path.wildcard("**/*.{exs,json,yml,yaml,config,env}")
    |> Enum.filter(&File.regular?/1)
  end

  defp find_dependency_files do
    ["mix.exs", "package.json", "requirements.txt", "Cargo.toml", "pom.xml", "build.gradle"]
    |> Enum.filter(&File.exists?/1)
  end

  defp extract_python_functions(_content), do: []
  defp extract_ruby_functions(_content), do: []
  defp extract_java_functions(_content), do: []
  defp extract_typescript_functions(_content), do: []
  defp extract_javascript_imports(_content), do: []
  defp extract_typescript_imports(_content), do: []
  defp extract_json_config_keys(_content), do: []
  defp extract_yaml_config_keys(_content), do: []
  defp find_unused_npm_dependencies(_file_path), do: []
end
