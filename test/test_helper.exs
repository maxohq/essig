ExUnit.configure(exclude: [disabled: true])
ExUnit.start(trace: true)
## Repo sandbox
Ecto.Adapters.SQL.Sandbox.mode(Scoped.Repo, :manual)

## Mneme setup
Mneme.start(restart: true)
