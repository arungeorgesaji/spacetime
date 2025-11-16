defmodule Spacetime.SCM.ObjectParser do
  @object_dir ".spacetime/objects"

  def store_object(data) when is_binary(data) do
    object_id = :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
    
    dir = String.slice(object_id, 0, 2)
    file = String.slice(object_id, 2, String.length(object_id) - 2)
    object_path = Path.join([@object_dir, dir, file])
    
    File.mkdir_p!(Path.dirname(object_path))
    
    compressed_data = :zlib.compress(data)
    File.write!(object_path, compressed_data)
    
    object_id
  end

  def get_object(object_id) when is_binary(object_id) and byte_size(object_id) == 0 do
    {:error, "Empty object ID"}
  end

  def get_object(nil) do
    {:error, "Nil object ID"}
  end

  def get_object(object_id) when is_binary(object_id) and byte_size(object_id) > 0 do
    dir = String.slice(object_id, 0, 2)
    file = String.slice(object_id, 2, String.length(object_id) - 2)
    object_path = Path.join([@object_dir, dir, file])
    
    case File.read(object_path) do
      {:ok, compressed_data} ->
        :zlib.uncompress(compressed_data)
        
      {:error, reason} ->
        {:error, "Object not found: #{reason}"}
    end
  end

  def object_exists?(object_id) do
    dir = String.slice(object_id, 0, 2)
    file = String.slice(object_id, 2, String.length(object_id) - 2)
    object_path = Path.join([@object_dir, dir, file])
    File.exists?(object_path)
  end

  def store_blob(content) do
    Spacetime.SCM.Internals.create_blob(content)
  end

  def read_blob(blob_id) do
    case get_object(blob_id) do
      {:error, reason} -> {:error, reason}
      object_data -> Spacetime.SCM.Internals.parse_blob(object_data)
    end
  end

  def get_object_type(object_id) do
    case get_object(object_id) do
      {:error, _} -> "unknown"
      object_data ->
        case String.split(object_data, " ", parts: 2) do
          [type, _] -> type
          _ -> "unknown"
        end
    end
  end

  def store_tree(entries) do
    Spacetime.SCM.Internals.create_tree(entries)
  end

  def read_tree(tree_id) do
    case get_object(tree_id) do
      {:error, reason} -> {:error, reason}
      object_data -> Spacetime.SCM.Internals.parse_tree(object_data)
    end
  end

  def list_objects do
    objects_dir = ".spacetime/objects"
    
    if File.exists?(objects_dir) do
      objects_dir
      |> File.ls!()
      |> Enum.filter(fn dir -> String.length(dir) == 2 end)
      |> Enum.flat_map(fn dir ->
        Path.join([objects_dir, dir])
        |> File.ls!()
        |> Enum.map(fn file -> dir <> file end)
      end)
      |> Enum.map(fn object_id ->
        {object_id, get_object_type(object_id)}
      end)
    else
      []
    end
  end

  def store_commit(commit_params) do
    Spacetime.SCM.Internals.create_commit(commit_params)
  end 

  def read_commit(commit_id) do
    case get_object(commit_id) do
      {:error, reason} -> {:error, reason}
      object_data -> Spacetime.SCM.Internals.parse_commit(object_data)
    end
  end

  def get_commit_history(commit_id) do
    Spacetime.SCM.Internals.get_commit_history(commit_id)
  end
end
