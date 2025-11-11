defmodule Spacetime.SCM.ObjectParser do
  @object_dir ".spacetime/objects"

  def store_object(data) when is_binary(data) do
    object_id = :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
    
    object_path = Path.join([@object_dir, String.slice(object_id, 0, 2), String.slice(object_id, 2..-1//1)])
    
    File.mkdir_p!(Path.dirname(object_path))
    
    compressed_data = :zlib.compress(data)
    File.write!(object_path, compressed_data)
    
    object_id
  end

  def get_object(object_id) do
    object_path = Path.join([@object_dir, String.slice(object_id, 0, 2), String.slice(object_id, 2..-1//1)])
    
    case File.read(object_path) do
      {:ok, compressed_data} ->
        data = :zlib.uncompress(compressed_data)
        {:ok, data}
        
      {:error, reason} ->
        {:error, "Object not found: #{reason}"}
    end
  end

  def object_exists?(object_id) do
    object_path = Path.join([@object_dir, String.slice(object_id, 0, 2), String.slice(object_id, 2..-1//1)])
    File.exists?(object_path)
  end

  def store_blob(content) do
    Spacetime.SCM.Internals.create_blob(content)
  end

  def read_blob(blob_id) do
    Spacetime.SCM.Internals.read_blob(blob_id)
  end

  def get_object_type(object_id) do
    with {:ok, object_data} <- get_object(object_id) do
      case String.split(object_data, " ", parts: 2) do
        [type, _] -> {:ok, type}
        _ -> {:error, "Unknown object type"}
      end
    end
  end

  def store_tree(entries) do
    Spacetime.SCM.Internals.create_tree(entries)
  end

  def read_tree(tree_id) do
    Spacetime.SCM.Internals.read_tree(tree_id)
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
        case get_object_type(object_id) do
          {:ok, type} -> {object_id, type}
          _ -> {object_id, "unknown"}
        end
      end)
    else
      []
    end
  end
end
