defmodule Spacetime.CLI.Main do
  @version "1.0"
  
  def setup do
    [
      name: "spacetime",
      description: "A version control system where code obeys the laws of physics",
      version: @version,
      author: "Arun George Saji",
      about: "Manage your code with cosmic principles",
      allow_unknown_args: false,
      parse_double_dash: true,
      subcommands: [
        init: [
          name: "init",
          about: "Initialize a new Spacetime repository",
          args: []
        ],
        add: [
          name: "add",
          about: "Stage files or directories",
          args: [
            files: [
              value_name: "FILES",
              help: "Files or directories to stage",
              required: true,
              multiple: true
            ]
          ]
        ],
        commit: [
          name: "commit",
          about: "Commit staged changes to the repository",
          args: [
            content: [
              value_name: "MESSAGE",
              help: "Commit message describing the changes",
              required: true
            ]
          ],
          flags: [
            event_horizon: [
              short: "-e",
              long: "--event-horizon",
              help: "Mark this as an irreversible Event Horizon commit",
              value: false
            ]
          ]
        ],
        log: [
          name: "log",
          about: "Show commit history",
          args: []
        ],
        branch: [
          name: "branch",
          about: "Create Or list branches",
          args: [
            name: [
              value_name: "NAME",
              help: "Name of the branch to create (if omitted, lists branches)",
              required: false
            ]
          ]
        ],
        "mass-report": [
          name: "mass-report",
          about: "Show gravitational mass calculations for branches",
          args: []
        ],
        status: [
          name: "status",
          about: "Show repository status",
          args: []
        ],
        redshift: [
          name: "redshift",
          about: "Show code aging and readability analysis",
          args: []
        ],
        "event-horizon": [
          name: "event-horizon",
          about: "Manage and inspect Event Horizon commits",
          args: []
        ],
        "debug-object": [
          name: "debug-object",
          about: "Test object storage and retrieval in Spacetime",
          args: [
            content: [
              value_name: "CONTENT",
              help: "Content to store and retrieve for testing",
              required: true
            ]
          ]
        ],
        "debug-store": [
          name: "debug-store",
          about: "Test blob storage and retrieval in Spacetime",
          args: [
            content: [
              value_name: "CONTENT",
              help: "Content to store and retrieve for testing",
              required: true
            ]
          ]
        ],
        "debug-tree": [
          name: "debug-tree",
          about: "Test blob storage and retrieval in Spacetime",
        ],
        "debug-list": [
          name: "debug-list",
          about: "List all stored objects (blobs, trees, commits) in the Spacetime repository",
        ],
        "debug-commit": [
          name: "debug-commit",
          about: "Test commit storage and retrieval in Spacetime",
        ],
        "debug-history": [
          name: "debug-history",
          about: "Show commit history in Spacetime",
        ],
      ]
    ]
  end
  
  def run(args) do
    optimus = Optimus.new!(setup())
    
    case Optimus.parse!(optimus, args) do
      {[:init], _parsed} ->
        init_repository()

      {[:add], parsed} ->
        handle_add({[:add], parsed})

      {[:commit], parsed} ->
        message = parsed.args.content
        event_horizon = parsed.flags[:event_horizon] || false

        if is_binary(message) and message != "" do
          if event_horizon do
            staged_files = Spacetime.Repo.get_staged_files()
            file_paths = Enum.map(staged_files, & &1["path"])

            Spacetime.CLI.Commands.EventHorizon.create_event_horizon(
              message,
              file_paths
            )
          else
            Spacetime.CLI.Commands.CosmicCommit.run(message)
          end
        else
          IO.puts("Commit message is required.\nUsage: spacetime commit \"message\"")
        end

      {[:log], _parsed} ->
        show_log()

      {[:branch], parsed} ->
        case parsed.args.name do
          nil -> 
            list_branches()

          "" -> 
            list_branches()   

          name when is_binary(name) -> 
            create_branch(name)
        end

      {[:"mass-report"], _parsed} -> 
        Spacetime.CLI.Commands.MassReport.run()

      {[:status], _parsed} ->
        show_status()

      {[:redshift], _parsed} ->
        Spacetime.CLI.Commands.RedshiftStatus.run()

      {[:"event-horizon"], _parsed} ->
        Spacetime.CLI.Commands.EventHorizon.run()

      {[:"debug-object"], parsed} ->
        content = parsed.args.content
        test_object_storage(content)

      {[:"debug-store"], parsed} ->
        content = parsed.args.content
        test_blob_storage(content)

      {[:"debug-tree"], _parsed} ->
        test_tree_storage()

      {[:"debug-commit"], _parsed} ->
        test_commit_storage()

      {[:"debug-history"], _parsed} ->
        test_commit_storage()

      {[:"debug-list"], _parsed} ->
        list_objects()

      {[], _parsed} ->
        IO.puts(Optimus.help(optimus))
        
      _ ->
        IO.puts("Unknown command")
        System.halt(1)
    end
  rescue
    e in RuntimeError ->
      IO.puts("Error: #{Exception.message(e)}")
      System.halt(1)
  end
  
  def main(args), do: run(args)
  
  defp init_repository do
    IO.puts("Initializing new Spacetime repository...")
    File.mkdir_p!(".spacetime/objects")
    File.mkdir_p!(".spacetime/refs/heads")
    File.mkdir_p!(".spacetime/staging")

    File.write!(".spacetime/HEAD", "ref: refs/heads/main")

    File.write!(".spacetime/refs/heads/main", "")
    
    config = %{
      version: 1,
      physics: %{
        redshift_enabled: true,
        gravity_enabled: true
      }
    }
    
    File.write!(".spacetime/config", Jason.encode!(config, pretty: true))
    IO.puts("Spacetime repository initialized!")
  end

  def handle_add({[:add], %{args: %{files: files}}}) do
    files =
      case files do
        list when is_list(list) -> list
        single when is_binary(single) -> [single]
      end

    Enum.each(files, &stage_path/1)
  end

  defp stage_path(path) do
    cond do
      File.regular?(path) ->
        stage_file(path)

      File.dir?(path) ->
        stage_directory(path)

      true ->
        IO.puts("Error: #{path} does not exist")
    end
  end

  defp stage_file(path) do
    case Spacetime.Repo.stage_file(path) do
      {:ok, path} ->
        IO.puts("Staged: #{path}")

      {:error, reason} ->
        IO.puts("Error staging #{path}: #{reason}")
    end
  end

  defp stage_directory(dir) do
    dir
    |> Path.join("**/*")
    |> Path.wildcard()
    |> Enum.filter(&File.regular?/1)
    |> Enum.each(&stage_file/1)
  end

  defp show_log do
    IO.puts "Commit History"
    IO.puts "=" <> String.duplicate("=", 40)
    
    head_ref = Spacetime.Repo.get_head()
    ref_path = ".spacetime/#{head_ref}"
    
    if File.exists?(ref_path) do
      latest_commit = File.read!(ref_path) |> String.trim()
      history = Spacetime.SCM.ObjectParser.get_commit_history(latest_commit)
      
      Enum.each(history, fn %{id: commit_id, data: commit_data} ->
        IO.puts "commit #{String.slice(commit_id, 0, 8)}"
        IO.puts "Author: #{commit_data.author |> List.first()}"
        IO.puts "Date:   #{commit_data.timestamp |> List.first()}"
        IO.puts ""
        IO.puts "    #{String.trim(commit_data.message)}"
        IO.puts ""
      end)
    else
      IO.puts "No commits yet"
    end
  end

  defp list_branches do
    branches = Spacetime.Repo.Branch.list_branches()
    current = Spacetime.Repo.Branch.get_current_branch()
    
    IO.puts "Branches:"
    Enum.each(branches, fn branch ->
      if branch == current do
        IO.puts "#{branch} (current)"
      else
        IO.puts "  #{branch}"
      end
    end)
  end

  defp create_branch(name) do
    case Spacetime.Repo.Branch.create_branch(name) do
      {:ok, branch_name} ->
        IO.puts "Created branch: #{branch_name}"
        
        branch_ref_path = ".spacetime/refs/heads/#{branch_name}"
        commit_id = File.read!(branch_ref_path) |> String.trim()
        
        if commit_id != "" do
          history = Spacetime.Repo.Branch.get_branch_history(branch_name)
          mass_data = Spacetime.Physics.Gravity.calculate_branch_mass(branch_name, history)
          IO.puts "Initial mass: #{Float.round(mass_data.total, 2)}"
        else
          IO.puts "Initial mass: 0.0 (no commits yet)"
        end
        
      {:error, reason} ->
        IO.puts "Error: #{reason}"
    end
  end
  
  defp show_status do
    IO.puts("Scanning spacetime continuum...")
    
    if File.exists?(".spacetime/config") do
      IO.puts("Repository: Spacetime-enabled")
      IO.puts("Physics: Redshift and Gravity primed")
      object_count = count_objects()
      IO.puts("Objects in storage: #{object_count}")
    else
      IO.puts("Not a spacetime repository")
      IO.puts("Run 'spacetime init' to begin")
    end
  end

  defp test_object_storage(content) do
    IO.puts "Testing object storage..."
    
    object_id = Spacetime.SCM.ObjectParser.store_object(content)
    IO.puts "Stored object: #{object_id}"
    
    case Spacetime.SCM.ObjectParser.get_object(object_id) do
      {:ok, retrieved_content} ->
        IO.puts "Retrieved object: #{retrieved_content}"
        IO.puts "Match: #{content == retrieved_content}"
        
      {:error, reason} ->
        IO.puts "Error retrieving: #{reason}"
    end
  end

  defp test_blob_storage(filename) do
    IO.puts "Testing blob storage..."
    
    if File.exists?(filename) do
      content = File.read!(filename)
      blob_id = Spacetime.SCM.ObjectParser.store_blob(content)
      
      IO.puts "Stored blob: #{blob_id}"
      IO.puts "File size: #{byte_size(content)} bytes"
      
      case Spacetime.SCM.ObjectParser.read_blob(blob_id) do
        {:ok, retrieved_content} ->
          IO.puts "Retrieved blob content"
          IO.puts "Content matches: #{content == retrieved_content}"
          
          case Spacetime.SCM.ObjectParser.get_object_type(blob_id) do
            {:ok, type} -> IO.puts "Object type: #{type}"
            _ -> IO.puts "Unknown object type"
          end
          
        {:error, reason} ->
          IO.puts "Error reading blob: #{reason}"
      end
    else
      IO.puts "File not found: #{filename}"
    end
  end

  defp test_tree_storage do
    IO.puts "Testing tree storage..."
    
    blob1_id = Spacetime.SCM.ObjectParser.store_blob("Hello from file1.txt!")
    blob2_id = Spacetime.SCM.ObjectParser.store_blob("Content of file2.txt")
    
    IO.puts "Created blobs:"
    IO.puts "   - file1.txt: #{blob1_id}"
    IO.puts "   - file2.txt: #{blob2_id}"
    
    entries = [
      %{name: "file1.txt", type: :blob, id: blob1_id, mode: "100644"},
      %{name: "file2.txt", type: :blob, id: blob2_id, mode: "100644"}
    ]
    
    tree_id = Spacetime.SCM.ObjectParser.store_tree(entries)
    IO.puts "Stored tree: #{tree_id}"
    
    IO.puts "Reading tree back..."
    case Spacetime.SCM.ObjectParser.read_tree(tree_id) do
      {:ok, retrieved_entries} ->
        IO.puts "Retrieved tree entries:"
        Enum.each(retrieved_entries, fn entry ->
          IO.puts "   - #{entry.mode} #{entry.type} #{String.slice(entry.id, 0, 8)} #{entry.name}"
        end)
        
      {:error, reason} ->
        IO.puts "Error reading tree: #{reason}"
        case Spacetime.SCM.ObjectParser.get_object(tree_id) do
          {:error, err} -> IO.puts "   get_object error: #{err}"
          data -> IO.puts "   get_object returned: #{inspect(String.slice(data, 0, 50))}..."
        end
    end

    tree_id
  end

  defp list_objects do
    IO.puts "Listing all objects:"
    
    objects = Spacetime.SCM.ObjectParser.list_objects()
    
    if Enum.empty?(objects) do
      IO.puts "   No objects found"
    else
      Enum.each(objects, fn {object_id, type} ->
        IO.puts "   - #{String.slice(object_id, 0, 16)}... (#{type})"
      end)
      IO.puts "Total: #{length(objects)} objects"
    end
  end
  
  defp count_objects do
    objects_dir = ".spacetime/objects"
    
    if File.exists?(objects_dir) do
      objects_dir
      |> File.ls!()
      |> Enum.filter(fn dir -> String.length(dir) == 2 end)
      |> Enum.flat_map(fn dir ->
        Path.join([objects_dir, dir])
        |> File.ls!()
      end)
      |> Enum.count()
    else
      0
    end
  end

  defp test_commit_storage do
    IO.puts "Testing commit storage..."
    
    tree_id = test_tree_storage()
    
    commit1_id = Spacetime.SCM.ObjectParser.store_commit(%{
      tree: tree_id,
      message: "Initial commit with two files",
      author: "Cosmic Developer <cosmic@spacetime.dev>",
      committer: "Spacetime SCM <system@spacetime.dev>"
    })
    
    IO.puts "Stored initial commit: #{commit1_id}"
    
    commit2_id = Spacetime.SCM.ObjectParser.store_commit(%{
      tree: tree_id,
      parent: commit1_id,
      message: "Second commit with spacetime physics",
      author: "Cosmic Developer <cosmic@spacetime.dev>",
      committer: "Spacetime SCM <system@spacetime.dev>"
    })
    
    IO.puts "Stored second commit: #{commit2_id}"
    
    IO.puts "\nReading commit #{String.slice(commit2_id, 0, 8)}:"
    case Spacetime.SCM.ObjectParser.read_commit(commit2_id) do
      {:ok, commit_data} ->
        IO.puts "   Tree: #{commit_data.tree |> List.first() |> String.slice(0, 8)}"
        IO.puts "   Parent: #{commit_data.parent |> List.first() |> String.slice(0, 8)}"
        IO.puts "   Author: #{commit_data.author |> List.first()}"
        IO.puts "   Message: #{String.trim(commit_data.message)}"
        IO.puts "   Spacetime: #{commit_data[:"spacetime-version"] |> List.first()}"
        
      {:error, reason} ->
        IO.puts "Error reading commit: #{reason}"
    end

    commit2_id
  end

  defp show_commit_history do
    IO.puts "Showing commit history..."
    
    commit_id = test_commit_storage()
    
    IO.puts "\nCommit history:"
    history = Spacetime.SCM.ObjectParser.get_commit_history(commit_id)
    
    Enum.each(history, fn %{id: commit_id, data: commit_data} ->
      IO.puts "   commit #{String.slice(commit_id, 0, 8)}"
      IO.puts "   Author: #{commit_data.author |> List.first()}"
      IO.puts "   Message: #{String.trim(commit_data.message)}"
      IO.puts "   ---"
    end)
    
    IO.puts "Total commits: #{length(history)}"
  end
end
