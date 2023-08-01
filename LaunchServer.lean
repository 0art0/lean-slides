import Lean

def markdownDir : System.FilePath := "." / "md"
def slidesDir : System.FilePath := "." / "slides"

def serverPort : Nat := 3000
def serverUrl : String := s!"http://localhost:{serverPort}"

def main : IO Unit := do
  let _stdioCfg ← IO.Process.spawn {
  cmd := "browser-sync",
  args := #[".", "--port", toString serverPort,
            "--watch", "--no-open"],
  cwd := "."
  }