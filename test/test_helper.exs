ExUnit.start(trace: false)

ExUnit.configure(exclude: [:skip])

# Setup for all tests
ExUnit.after_suite(fn _ ->
  # Reset the Context after all tests
  Context.set_current_app(nil)
end)

# Ensure ChildRegistry is started for tests
Application.ensure_all_started(:supernamed)
