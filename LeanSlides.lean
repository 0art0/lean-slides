import ProofWidgets.Component.HtmlDisplay
import LeanSlides.Init

open Lean ProofWidgets Elab Parser Command Server System

section Utils

def markdownDir : IO System.FilePath := return ((← IO.currentDir) / "md").normalize
def slidesDir : IO System.FilePath := return ((← IO.currentDir) / "slides").normalize -- this must be in sync with the `slidesDir` in the `lakefile`

def getServerPort : IO String := do
  match ← IO.getEnv "LEANSLIDES_PORT" with
  | some port => return port
  | none => return "3000"

def getServerUrl : IO String := do
  let url := s!"http://localhost:{← getServerPort}/"
  try
    let out ← IO.Process.output { cmd := "curl", args := #[url] }
    if out.exitCode != 0 then
      IO.eprintln "The server for `Lean Slides` is not running."
      IO.eprintln "It can be started using the command `lake run lean-slides/serve-slides`."
  catch err => IO.eprintln err
  return url

def System.FilePath.getRelativePath (filePath : FilePath) : String :=
  if filePath.isRelative then
    filePath.normalize.toString.dropWhile (· ≠ FilePath.pathSeparator) |>.toString
  else
    panic! s!"The file path {filePath} is not a relative path."

def extractModuleDocContent : TSyntax ``moduleDoc → String
  | ⟨.node _ _ #[_, .atom _ doc]⟩ => doc.dropEnd 2 |>.toString
  | _ => panic! "Ill-formed module docstring."

def createMarkdownFile (title text : String) : IO FilePath := do
  let markdownDir ← markdownDir
  let mdFile := markdownDir / (title ++ ".md")
  unless ← markdownDir.pathExists do
    IO.FS.createDir markdownDir
  IO.FS.writeFile mdFile text
  return mdFile

def runPandoc (mdFile : FilePath) : IO FilePath := do
  let markdownDir ← markdownDir
  let slidesDir ← slidesDir

  unless (← mdFile.pathExists) && mdFile.extension = some "md" do
    IO.throwServerError s!"The file {mdFile} is not a valid Markdown file."
  unless mdFile.parent = some markdownDir do
    IO.throwServerError s!"The file {mdFile} is not in the directory {markdownDir}."

  let htmlFile : FilePath := slidesDir / (mdFile.fileStem.get! ++ ".html")
  unless ← slidesDir.pathExists do
    IO.FS.createDir slidesDir
  let styleSheet ← do
    if ← (slidesDir / "style.css").pathExists then
      pure #["--css=" ++ (← getServerUrl) ++ "style.css"]
    else pure #[]
  let out ← IO.Process.run {
    cmd := "pandoc",
    args := #["-s", "--katex",
              "-t", "revealjs"] ++
            (← LeanSlides.pandocOptions.get) ++
            styleSheet ++
            [ mdFile.toString,
              "-o", htmlFile.toString]
  }
  IO.println out
  return htmlFile

open scoped ProofWidgets.Jsx in
def iframeComponent (url : String) :=
  <iframe src={url} width="100%" height="500px" frameBorder="0" />

end Utils

section Caching

initialize slidesCache : IO.Ref (Std.HashMap (String × String) String) ← IO.mkRef ∅

def createSlidesFor (title : String) (content : String) : CommandElabM Unit := do
  let ref ← slidesCache.get
  if ← getBoolOption `leanSlides.cache_slides then
    if let some htmlFileContents := ref[(title, content)]? then
      IO.FS.writeFile ((← slidesDir) / s!"{title}.html") htmlFileContents
      return
  let mdFile ← createMarkdownFile title content
  let htmlFile ← runPandoc mdFile
  slidesCache.set <| ref.insert (title, content) (← IO.FS.readFile htmlFile)

end Caching

section Widget

syntax (name := slidesCmd) "#slides" ("+draft")? ident moduleDoc : command

@[command_elab slidesCmd] def revealSlides : CommandElab
  | stx@`(command| #slides $title $doc) => do
    let name := title.getId.toString
    let content := extractModuleDocContent doc
    createSlidesFor name content
    let slidesUrl := (← getServerUrl)  ++ s!"{name}.html"
    IO.println s!"Rendering results for {name} hosted at {slidesUrl} ..."
    -- TODO: Check whether the server is up programmatically
    IO.println "Ensure that the server is running ..."
    let slides := iframeComponent slidesUrl
    runTermElabM fun _ ↦ do
      Widget.savePanelWidgetInfo (hash HtmlDisplayPanel.javascript) (do
        return .mkObj [("html", ← rpcEncode slides)])
        stx
  | `(command| #slides +draft%$tk $_ $_) =>
    logInfoAt tk m!"Slides are not rendered in draft mode."
  | _ => throwUnsupportedSyntax

end Widget
