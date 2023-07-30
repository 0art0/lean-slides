import ProofWidgets.Component.HtmlDisplay
import Std.CodeAction.Misc

open Lean ProofWidgets Elab Parser Command Server System

section Utils

def launchHttpServer (port := 8080) : IO String := do
  let _stdioCfg ← IO.Process.spawn {
    cmd := "http-server",
    args := #["--port", toString port, 
              "--ext", "html"],
    cwd := some "."
  }
  return s!"http://localhost:{port}"

def System.FilePath.getRelativePath (filePath : FilePath) : String :=
  if filePath.isRelative then
    filePath.normalize.toString.dropWhile (· ≠ FilePath.pathSeparator)
  else 
    panic! s!"The file path {filePath} is not a relative path."

def extractModuleDocContent : TSyntax ``moduleDoc → String
  | ⟨.node _ _ #[_, .atom _ doc]⟩ => doc.dropRight 2
  | _ => panic! "Ill-formed module docstring."

def markdownDir : FilePath := "." / "md"
def slidesDir : FilePath := "." / "slides"

def createMarkdownFile (title text : String) : IO FilePath := do
  let mdFile := markdownDir / (title ++ ".md")
  unless ← markdownDir.pathExists do
    IO.FS.createDir markdownDir
  IO.FS.writeFile mdFile text
  return mdFile

def runPandoc (mdFile : FilePath) : IO FilePath := do
  unless (← mdFile.pathExists) && mdFile.extension = some "md" do
    IO.throwServerError s!"The file {mdFile} is not a valid Markdown file."
  unless mdFile.parent = some markdownDir do
    IO.throwServerError s!"The file {mdFile} is not in the `md` directory."
  
  let htmlFile : FilePath := slidesDir / (mdFile.fileStem.get! ++ ".html")
  unless ← slidesDir.pathExists do
    IO.FS.createDir slidesDir 
  let out ← IO.Process.run {
    cmd := "pandoc",
    args := #["-s", "--katex", 
              "-t", "revealjs", 
              mdFile.toString, 
              "-o", htmlFile.toString],
    cwd := some "."
  }
  IO.println out
  return htmlFile

open scoped ProofWidgets.Jsx in
def iframeComponent (url : String) :=
  <iframe src={url} width="100%" height="500px" frameBorder="0" />

end Utils

section Caching

initialize slidesCache : IO.Ref (HashMap (String × String) FilePath) ← IO.mkRef ∅
initialize serverUrl : IO.Ref String ← IO.mkRef ""

def getServerUrl : IO String := do
  return s!"http://localhost:{8080}"

def getSlidesFor (title : String) (content : String) : IO FilePath := do
  let ref ← slidesCache.get
  match ref.find? (title, content) with
    | some filePath => return filePath
    | none => 
      let mdFile ← createMarkdownFile title content
      let htmlFile ← runPandoc mdFile
      slidesCache.set <| ref.insert (title, content) htmlFile
      return htmlFile

end Caching

section Widget

syntax (name := slidesCmd) "#slides" ("+draft")? ident moduleDoc : command

@[command_elab slidesCmd] def revealSlides : CommandElab
  | stx@`(command| #slides $title $doc) => do
    let name := title.getId.toString
    let content := extractModuleDocContent doc
    let slidesPath ← getSlidesFor name content
    let slidesUrl := (← getServerUrl) ++ slidesPath.getRelativePath
    IO.println s!"Rendering results for {name} hosted at {slidesUrl} ..."
    let slides := Html.ofTHtml <| iframeComponent slidesUrl
    runTermElabM fun _ ↦ do 
      savePanelWidgetInfo stx ``HtmlDisplayPanel <| do
        return .mkObj [("html", ← rpcEncode slides)]
  | `(command| #slides +draft%$tk $_ $_) => 
    logInfoAt tk m!"Slides are not rendered in draft mode."
  | _ => throwUnsupportedSyntax

open Std CodeAction in
@[command_code_action slidesCmd]
def draftSlidesCodeAction : CommandCodeAction := fun _ _ _ node ↦ do
  let .node info _ := node | return #[]
  let doc ← RequestM.readDoc
  match info.stx with
    | `(command| #slides%$tk $_:ident $_:moduleDoc) => 
      let eager : Lsp.CodeAction := {
        title := "Convert to draft slides.",
        kind? := "quickfix",
        isPreferred? := true
      }
      return #[{
        eager
        lazy? := some do
          let some pos := tk.getTailPos? | return eager
          return { eager with 
            edit? := some <| .ofTextEdit doc.meta.uri {
              range := doc.meta.text.utf8RangeToLspRange ⟨pos, pos⟩,
              newText := " +draft" } }
      }]
    | `(command| #slides +draft%$tk $_:ident $_:moduleDoc) => 
      let eager : Lsp.CodeAction := {
        title := "Convert to live slides.",
        kind? := "quickfix",
        isPreferred? := true
      }
      return #[{
        eager
        lazy? := some do
          let some startPos := tk.getPos? | return eager
          let some endPos := tk.getTailPos? | return eager
          return { eager with 
            edit? := some <| .ofTextEdit doc.meta.uri {
              range := doc.meta.text.utf8RangeToLspRange ⟨startPos, ⟨endPos.byteIdx + 1⟩⟩,
              newText := "" } }
      }]
    | _ => return #[]

end Widget