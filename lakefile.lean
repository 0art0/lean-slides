import Lake
open Lake DSL

package «lean-slides» {
  precompileModules := true
}

@[default_target]
lean_lib LeanSlides where

@[default_target]
lean_exe «lean-slides» {
  root := `LeanSlides
}

require proofwidgets from git "https://github.com/leanprover-community/ProofWidgets4" @ "v0.0.63"


section Scripts

def getPort : IO String := do
  let defaultPort := 3000
  match ← IO.getEnv "LEANSLIDES_PORT" with
  | some port => return port
  | none => do
    IO.println "Could not find `LEANSLIDES_PORT` variable in environment"
    IO.println s!"Using default port {defaultPort} instead ..."
    return toString defaultPort

def slidesDir : IO System.FilePath :=
  return (← IO.currentDir) / "slides" |>.normalize

script «serve-slides» do
  IO.println "Starting HTTP server for `Lean Slides` ..."
  let slidesDir ← slidesDir
  unless (← slidesDir.pathExists) do
    IO.FS.createDir slidesDir
  let _stdioCfg ← IO.Process.spawn {
    cmd := "browser-sync",
    args := #[slidesDir.toString, "--port", ← getPort,
              "--watch", "--no-open"],
    cwd := "."
  }
  return 0

end Scripts
