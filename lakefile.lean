import Lake
open Lake DSL

package «lean-slides» {
  precompileModules := true
}

@[default_target]
lean_exe «lean-slides» {
  root := `LeanSlides
}

require proofwidgets from git "https://github.com/EdAyers/ProofWidgets4" @ "v0.0.13"
require std from git "https://github.com/leanprover/std4/" @ "main"


section Scripts

def getPort : IO String := do
  let defaultPort := 3000
  match ← IO.getEnv "LEANSLIDES_PORT" with
  | some port => return port
  | none => do
    IO.println "Could not find `LEANSLIDES_PORT` variable in environment"
    IO.println "Using default port {defaultPort} instead ..."
    return toString defaultPort

script serve_slides do
  IO.println "Starting HTTP server for `Lean Slides` ..."
  let _stdioCfg ← IO.Process.spawn {
    cmd := "browser-sync",
    args := #[".", "--port", ← getPort,
              "--watch", "--no-open"],
    cwd := "."
  }
  return 0

end Scripts