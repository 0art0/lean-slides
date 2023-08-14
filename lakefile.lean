import Lake
open Lake DSL

package leanSlides {
  precompileModules := true
}

@[default_target]
lean_exe leanSlides {
  root := `LeanSlides
}

require proofwidgets from git "https://github.com/EdAyers/ProofWidgets4" @ "v0.0.13"
require std from git "https://github.com/leanprover/std4/" @ "main"


section Scripts

def portFile : System.FilePath := "port"

script get_port do
  let port ← IO.FS.readFile portFile
  IO.println port
  return 0

script set_port (args) do
  let [port] := args | throw <| IO.userError "Expected exactly one argument."
  IO.FS.writeFile portFile port
  IO.println s!"The port for `LeanSlides` has been set to {port}."
  return 0

script serve_slides do
  IO.println "Starting HTTP server for `LeanSlides` ..."
  let serverPort ← IO.FS.readFile portFile
  let _stdioCfg ← IO.Process.spawn {
    cmd := "browser-sync",
    args := #[".", "--port", serverPort,
              "--watch", "--no-open"],
    cwd := "."
  }
  return 0

end Scripts