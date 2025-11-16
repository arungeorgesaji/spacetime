defmodule Spacetime.Repo do
  def init do
    File.mkdir_p!(".spacetime/objects")
    File.mkdir_p!(".spacetime/refs/heads")
    File.mkdir_p!(".spacetime/staging")
    
    set_head("refs/heads/main")
    
    config = %{
      version: 1,
      physics: %{
        redshift_enabled: true,
        gravity_enabled: true,
        event_horizon_enabled: false
      }
    }
    
    File.write!(".spacetime/config", Jason.encode!(config, pretty: true))
    :ok
  end

  def set_head(ref) do
    File.write!(".spacetime/HEAD", ref)
  end

  def get_head do
    case File.read(".spacetime/HEAD") do
      {:ok, "ref: " <> ref} -> String.trim(ref)
      {:ok, ref} -> String.trim(ref)
      _ -> "refs/heads/main"
    end
  end

  def stage_file(file_path) do
    if File.exists?(file_path) do
      content = File.read!(file_path)
      blob_id = Spacetime.SCM.ObjectParser.store_blob(content)
      
      staging_info = %{
        path: file_path,
        blob_id: blob_id,
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
      }
      
      staging_path = Path.join([".spacetime/staging", Base.url_encode64(file_path)])
      File.write!(staging_path, Jason.encode!(staging_info))
      
      {:ok, file_path}
    else
      {:error, "File not found: #{file_path}"}
    end
  end

  def get_staged_files do
    staging_dir = ".spacetime/staging"
    
    if File.exists?(staging_dir) do
      staging_dir
      |> File.ls!()
      |> Enum.map(fn encoded_path ->
        _path = Base.url_decode64!(encoded_path)
        content = File.read!(Path.join(staging_dir, encoded_path))
        Jason.decode!(content)
      end)
    else
      []
    end
  end

  def get_branch_commit(branch_name) do
    branch_path = ".spacetime/refs/heads/#{branch_name}"
    
    if File.exists?(branch_path) do
      File.read!(branch_path) |> String.trim()
    else
      ""
    end
  end

  def clear_staging do
    staging_dir = ".spacetime/staging"
    if File.exists?(staging_dir) do
      File.rm_rf!(staging_dir)
      File.mkdir_p!(staging_dir)
    end
  end
end
