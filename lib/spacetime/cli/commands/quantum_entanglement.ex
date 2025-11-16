defmodule Spacetime.CLI.Commands.QuantumEntanglement do
  alias Spacetime.Physics.Quantum

  def run do
    IO.puts("""
    Quantum Entanglement Commands:
    
    spacetime quantum-entangle <branch1> <branch2>    - Create entanglement
    spacetime quantum-disentangle <branch1> <branch2> - Remove entanglement  
    spacetime quantum-status                          - Show entanglements
    """)
  end

  def entangle(branch1, branch2, options \\ %{}) do
    IO.puts("Creating quantum entanglement between #{branch1} and #{branch2}...")
    
    case Quantum.create_entanglement(branch1, branch2, options) do
      {:ok, entanglement} ->
        IO.puts("Quantum entanglement created!")
        IO.puts("   Strength: #{entanglement.strength}")
        IO.puts("   Direction: #{if entanglement.bidirectional, do: "bidirectional", else: "unidirectional"}")
        IO.puts("   Entanglement ID: #{String.slice(entanglement.id, 0, 8)}")
        
      {:error, reason} ->
        IO.puts("Failed to create entanglement: #{reason}")
    end
  end

  def disentangle(branch1, branch2) do
    IO.puts("Removing quantum entanglement between #{branch1} and #{branch2}...")
    
    case Quantum.remove_entanglement(branch1, branch2) do
      {:ok, _} ->
        IO.puts("Quantum entanglement removed!")
        
      {:error, reason} ->
        IO.puts("Failed to remove entanglement: #{reason}")
    end
  end

  def status do
    IO.puts("Quantum Entanglement Status")
    IO.puts("=" <> String.duplicate("=", 40))
    
    entanglements = Quantum.list_entanglements()
    
    if Enum.empty?(entanglements) do
      IO.puts("No active quantum entanglements")
    else
      Enum.each(entanglements, fn entanglement ->
        direction = if entanglement.bidirectional, do: "↔", else: "→"
        IO.puts("#{entanglement.branch1} #{direction} #{entanglement.branch2}")
        IO.puts("  Strength: #{entanglement.strength}")
        IO.puts("  Created: #{entanglement.created_at}")
        IO.puts("  Sync Count: #{entanglement.sync_count}")
        IO.puts("")
      end)
    end
  end
end
