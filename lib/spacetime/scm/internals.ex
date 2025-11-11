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
    with {:ok, object_data} <- Spacetime.SCM.ObjectParser.get_object(blob_id),
         {:ok, content} <- parse_blob(object_data) do
      {:ok, content}
    else
      error -> error
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

  def read_tree(tree_id) do
    with {:ok, object_data} <- Spacetime.SCM.ObjectParser.get_object(tree_id),
         {:ok, entries} <- parse_tree(object_data) do
      {:ok, entries}
    else
      error -> error
    end
  end
end
