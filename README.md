# Spacetime
Spacetime is a version control system which recognizes that as stars and galaxies evolve, so does your codebase exist and 
it ages, gains complexity, and accumulates technical debt. By modeling code evolution through the lens of astrophysics, Spacetime introduces novel concepts like Redshift, Event Horizons, and Branch Gravity to help developers manage the lifecycle of their code more effectively.

## Core Concepts
Additional to basic version control features, Spacetime introduces physics-inspired concepts to manage code evolution.

### Redshift
Code gradually becomes harder to read over time, like light from distant galaxies.

**What it does:**
- Tracks file age and staleness
- Identifies legacy code needing documentation refresh
- Visualizes code aging with heat maps

**Why it matters:** Prevents ancient code from becoming unmaintainable black boxes.

### Event Horizon
Some commits are points of no return—once merged, they cannot be reverted.

**What it does:**
- Cryptographic commitment to breaking changes
- Automatic migration of dependent code
- Forces proper deprecation cycles

**Why it matters:** Eliminates the dangerous "we can always revert" mentality.

### Branch Gravity
Branches accumulate mass based on size and age, making them harder to diverge from.

**What it does:**
- Calculates "escape velocity" for new features
- Prevents massive merge conflicts from ancient branches
- Visualizes branch relationships as orbital mechanics

**Why it matters:** Long-lived branches become gravitational wells that are expensive to merge.

### Wormhole Merges
Merge parallel universes where both features coexist without conflict.
Smart conflict resolution that maintains both code paths, perfect for experimental features(Note: Strageties for conflict resolution like feature flags not implemented in the current version).

### Dark Matter Detection
Find code that has gravitational influence but isn't directly observable.
Cleans up technical debt that silently affects build times and performance.

### Quantum Entanglement
Link repositories so commits in one instantly appear in another.
Perfect for microservices where API and client libraries must version together.

### Big Bang Reset (Not implemented yet)
Rewrite git history while preserving spacetime properties.
Like git rebase -i but maintains physics metadata.

## Visualization

### Gravity Map
View your repository as a galaxy with files as stars sized by their mass.
Shows:
- File sizes as star masses
- Branches as orbital paths
- Gravitational pull indicators
- Merge difficulty predictions

### Redshift Timeline
Heat map showing code aging levels across your codebase.
Shows:
- Age-based color coding (blue = new, red = ancient)
- Predicted "unreadability horizon"
- Recommended refactoring targets

### Physics Layer
- Redshift: Code aging calculations
- Gravity: Branch mass and merge difficulty
- Event Horizon: Point-of-no-return commits

### SCM Layer
- Object Parser: Internal object storage system
- Pack Reader: Efficient data compression and storage
- Internals: Low-level version control operations

Spacetime implements its own object storage, commit tracking, and branching system with physics built into the core data structures.

### Cosmic Insights  
Comprehensive overview of repository's physics state, combining data from all the physics systems.

> "In space, no one can hear your merge conflicts."

## Command Reference

### Basic Commands

#### `spacetime init`
Initialize a new Spacetime repository in the current directory.

```bash
spacetime init
```

#### `spacetime add <files>`
Stage files or directories for commit.

```bash
spacetime add file.ex
spacetime add src/ lib/
```

#### `spacetime commit <message>`
Commit staged changes to the repository.

```bash
spacetime commit "Fix bug in parser"
spacetime commit "Breaking change" --event-horizon
```

**Flags:**
- `-e, --event-horizon` - Mark as irreversible Event Horizon commit

#### `spacetime status`
Show repository status, including physics metrics.

```bash
spacetime status
```

#### `spacetime log`
Display commit history with author, date, and message.

```bash
spacetime log
```

#### `spacetime branch [name]`
Create or list branches. Shows initial gravitational mass.

```bash
spacetime branch              # List all branches
spacetime branch new-feature  # Create new branch
```

#### `spacetime checkout <branch>`
Switch to a different branch.

```bash
spacetime checkout main
```

---

### Physics Commands

#### `spacetime redshift`
Analyze code aging and readability degradation.

```bash
spacetime redshift
```

Shows:
- Files with high redshift values
- Code age in days
- Change frequency
- Readability factors

#### `spacetime redshift-viz`
Visualize code aging with enhanced formatting.

```bash
spacetime redshift-viz
spacetime redshift-viz --format timeline
spacetime redshift-viz --since 2024-01-01
spacetime redshift-viz --threshold 0.8 --show-improvements
```

**Options:**
- `-f, --format <FORMAT>` - Output format: `text`, `timeline`, `json` (default: text)
- `-s, --since <DATE>` - Show changes since date (YYYY-MM-DD)
- `-t, --threshold <VALUE>` - Redshift threshold for highlighting (0.0-1.0, default: 0.7)
- `-i, --show-improvements` - Show code that improved (blueshift)

#### `spacetime mass-report`
Show gravitational mass calculations for all branches.

```bash
spacetime mass-report
```

Displays:
- Total mass per branch
- Commit count
- Mass breakdown by commit type
- Gravitational influence

#### `spacetime gravity-viz`
Visualize gravitational relationships between branches.

```bash
spacetime gravity-viz
spacetime gravity-viz --format graph
spacetime gravity-viz --threshold 0.5 --show-entanglements
```

**Options:**
- `-f, --format <FORMAT>` - Output format: `text`, `graph`, `json` (default: text)
- `-t, --threshold <MASS>` - Minimum mass threshold to display (default: 0.1)
- `-e, --show-entanglements` - Show quantum entanglements

#### `spacetime cosmic-insights`
Get comprehensive cosmic analysis of your repository.

```bash
spacetime cosmic-insights
spacetime cosmic-insights --detailed
spacetime cosmic-insights --json
```

**Flags:**
- `-d, --detailed` - Show detailed analysis
- `-j, --json` - Output as JSON

---

### Event Horizon Commands

#### `spacetime event-horizon`
Manage and inspect Event Horizon commits (points of no return).

```bash
spacetime event-horizon
```

Lists all Event Horizon commits with:
- Commit hash
- Message
- Affected files
- Migration guides

---

### Dark Matter Commands

#### `spacetime dark-matter [files]`
Detect unused code, imports, and configurations.

```bash
spacetime dark-matter                    # Scan entire repository
spacetime dark-matter src/              # Scan specific directory
spacetime dark-matter --cleanup         # Auto-remove detected dark matter
```

**Options:**
- `-c, --cleanup` - Automatically remove detected dark matter

**Detects:**
- Unused imports
- Dead functions
- Unreferenced files
- Phantom dependencies

---

### Wormhole Merge Commands

#### `spacetime wormhole-merge <source> <target>`
Merge branches while preserving both feature implementations.

```bash
spacetime wormhole-merge feature-a main
spacetime wormhole-merge feature-a main --feature-name new_api
spacetime wormhole-merge feature-a main --strategy environment
```

**Options:**
- `-f, --feature-name <NAME>` - Name for the feature flag
- `-s, --strategy <STRATEGY>` - Merge strategy: `feature-flag`, `environment`, `time`, `user`

#### `spacetime wormhole-check <source> <target>`
Check if branches can be wormhole merged.

```bash
spacetime wormhole-check feature-a main
```

#### `spacetime wormhole-strategies`
List available wormhole merge strategies.

```bash
spacetime wormhole-strategies
```

---

### Quantum Entanglement Commands

#### `spacetime quantum-entangle <branch1> <branch2>`
Create quantum entanglement between two branches.

```bash
spacetime quantum-entangle api client
spacetime quantum-entangle api client --bidirectional
spacetime quantum-entangle api client --strength strong
```

**Options:**
- `-b, --bidirectional` - Enable bidirectional synchronization
- `-s, --strength <LEVEL>` - Entanglement strength: `weak`, `medium`, `strong` (default: medium)

**Strength Levels:**
- `weak` - Manual sync triggers only
- `medium` - Auto-sync on commit (default)
- `strong` - Real-time synchronization

#### `spacetime quantum-disentangle <branch1> <branch2>`
Remove quantum entanglement between branches.

```bash
spacetime quantum-disentangle api client
```

#### `spacetime quantum-status`
Show current quantum entanglements.

```bash
spacetime quantum-status
```

---

> *"In space, no one can hear your merge conflicts."*
