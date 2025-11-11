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
end
