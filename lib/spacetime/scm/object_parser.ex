defmodule Spacetime.SCM.ObjectParser do
  @object_dir ".spacetime/objects"

  def store_object(data) when is_binary(data) do
    object_id = :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
    
    object_path = Path.join([@object_dir, String.slice(object_id, 0, 2), String.slice(object_id, 2..-1//-1)])
    
    File.mkdir_p!(Path.dirname(object_path))
    
    compressed_data = :zlib.compress(data)
    File.write!(object_path, compressed_data)
    
    object_id
  end

  def get_object(object_id) do
    object_path = Path.join([@object_dir, String.slice(object_id, 0, 2), String.slice(object_id, 2..-1//-1)])
    
    case File.read(object_path) do
      {:ok, compressed_data} ->
        data = :zlib.uncompress(compressed_data)
        {:ok, data}
        
      {:error, reason} ->
        {:error, "Object not found: #{reason}"}
    end
  end

  def object_exists?(object_id) do
    object_path = Path.join([@object_dir, String.slice(object_id, 0, 2), String.slice(object_id, 2..-1//-1)])
    File.exists?(object_path)
  end
end
