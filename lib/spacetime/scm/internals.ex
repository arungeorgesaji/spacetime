defmodule Spacetime.SCM.Internals do
  def create_blob(content) when is_binary(content) do
    header = "blob #{byte_size(content)}\0"
    blob_data = header <> content
    Spacetime.SCM.ObjectParser.store_object(blob_data)
  end

  def parse_blob(object_data) do
    case String.split(object_data, "\0", parts: 2) do
      [header, content] ->
        case String.split(header, " ") do
          ["blob", size] ->
            expected_size = String.to_integer(size)
            actual_size = byte_size(content)
            
            if expected_size == actual_size do
              {:ok, content}
            else
              {:error, "Size mismatch: expected #{expected_size}, got #{actual_size}"}
            end
            
          _ ->
            {:error, "Invalid blob header"}
        end
        
      _ ->
        {:error, "Invalid blob format"}
    end
  end

  def read_blob(blob_id) do
    case Spacetime.SCM.ObjectParser.get_object(blob_id) do
      {:error, reason} -> {:error, reason}
      object_data -> parse_blob(object_data)
    end
  end

  def create_tree(entries) when is_list(entries) do
    tree_content = Enum.map(entries, fn entry ->
      mode = entry.mode || "100644"
      type = case entry.type do
        :blob -> "blob"
        :tree -> "tree"
        _ -> "blob"
      end
      "#{mode} #{type} #{entry.id}\t#{entry.name}"
    end)
    |> Enum.join("\n")

    header = "tree #{byte_size(tree_content)}\0"
    tree_data = header <> tree_content
    Spacetime.SCM.ObjectParser.store_object(tree_data)
  end

  def parse_tree(object_data) do
    case String.split(object_data, "\0", parts: 2) do
      [header, content] ->
        case String.split(header, " ") do
          ["tree", size] ->
            expected_size = String.to_integer(size)
            actual_size = byte_size(content)
            
            if expected_size == actual_size do
              entries = parse_tree_entries(content)
              {:ok, entries}
            else
              {:error, "Size mismatch: expected #{expected_size}, got #{actual_size}"}
            end
            
          _ ->
            {:error, "Invalid tree header"}
        end
        
      _ ->
        {:error, "Invalid tree format"}
    end
  end

  defp parse_tree_entries(content) do
    content
    |> String.split("\n")
    |> Enum.filter(fn line -> line != "" end)
    |> Enum.map(fn line ->
      case String.split(line, "\t", parts: 2) do
        [meta, name] ->
          case String.split(meta, " ", parts: 3) do
            [mode, type, id] ->
              %{
                mode: mode,
                type: String.to_atom(type),
                id: id,
                name: name
              }
            _ ->
              nil
          end
        _ ->
          nil
      end
    end)
    |> Enum.filter(& &1)
  end

  def create_commit(%{tree: tree_id, message: message} = params) do
    headers = [
      "tree #{tree_id}",
      "author #{params[:author] || "Unknown <unknown@localhost>"}",
      "committer #{params[:committer] || "Unknown <unknown@localhost>"}",
      "timestamp #{params[:timestamp] || DateTime.utc_now() |> DateTime.to_iso8601()}",
    ]

    headers = if params[:parent] do
      ["parent #{params[:parent]}" | headers]
    else
      headers
    end

    files_in_commit = case read_tree(tree_id) do
      {:ok, entries} ->
        Enum.flat_map(entries, fn entry ->
          case entry.type do
            :blob -> [entry.name]
            :tree -> [] 
          end
        end)
      _ -> []
    end

    headers = headers ++ ["files #{Enum.join(files_in_commit, ",")}"]

    headers = headers ++ [
      "spacetime-version 0.1.0",
      "redshift 0.0",
      "gravity-mass 0.0"
    ]

    headers_str = Enum.join(headers, "\n")
    commit_content = headers_str <> "\n\n" <> message

    header = "commit #{byte_size(commit_content)}\0"
    commit_data = header <> commit_content
    Spacetime.SCM.ObjectParser.store_object(commit_data)
  end

  def read_tree(tree_id) do
    case Spacetime.SCM.ObjectParser.get_object(tree_id) do
      {:error, reason} -> {:error, reason}
      object_data -> parse_tree(object_data)
    end
  end

  def get_commit_files(commit_id) do
    case read_commit(commit_id) do
      {:ok, commit_data} ->
        case commit_data[:files] do
          [files_str | _] -> String.split(files_str, ",")
          _ -> []
        end
        
      {:error, _} ->
        []
    end
  end

  def file_in_commit?(commit_id, file_path) do
    files = get_commit_files(commit_id)
    file_path in files
  end

  def find_latest_commit_for_file(file_path, commit_history) do
    commit_history
    |> Enum.find(fn %{id: commit_id} ->
      file_in_commit?(commit_id, file_path)
    end)
  end

  def parse_commit(object_data) do
    case String.split(object_data, "\0", parts: 2) do
      [header, content] ->
        case String.split(header, " ") do
          ["commit", size] ->
            expected_size = String.to_integer(size)
            actual_size = byte_size(content)
            
            if expected_size == actual_size do
              parse_commit_content(content)
            else
              {:error, "Size mismatch: expected #{expected_size}, got #{actual_size}"}
            end
            
          _ ->
            {:error, "Invalid commit header"}
        end
        
      _ ->
        {:error, "Invalid commit format"}
    end
  end

  defp parse_commit_content(content) do
    [headers_part, message] = String.split(content, "\n\n", parts: 2)
    
    headers = headers_part
    |> String.split("\n")
    |> Enum.reduce(%{}, fn line, acc ->
      case String.split(line, " ", parts: 2) do
        [key, value] ->
          key = String.to_atom(key)
          Map.update(acc, key, [value], &(&1 ++ [value]))
        _ ->
          acc
      end
    end)
    |> Map.update(:message, message, fn _ -> message end)

    {:ok, headers}
  end

  def read_commit(commit_id) do
    case Spacetime.SCM.ObjectParser.get_object(commit_id) do
      {:error, reason} -> {:error, reason}
      object_data -> parse_commit(object_data)
    end
  end

  def get_commit_history(commit_id) do
    get_commit_history(commit_id, [])
  end

  defp get_commit_history(commit_id, acc) do
    case read_commit(commit_id) do
      {:ok, commit_data} ->
        history = [%{id: commit_id, data: commit_data} | acc]
        
        case commit_data[:parent] do
          [parent_id | _] -> get_commit_history(parent_id, history)
          _ -> history
        end
        
      {:error, _} ->
        acc
    end
  end
end
