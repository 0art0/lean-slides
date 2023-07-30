import ProofWidgets.Component.HtmlDisplay

open Lean ProofWidgets Elab Parser Command Server System Jsx Json

set_option autoImplicit false

def markdownDir : FilePath := "." / "md"
def slidesDir : FilePath := "." / "slides"

def extractModuleDocContent : TSyntax ``moduleDoc → String
  | ⟨.node _ _ #[_, .atom _ doc]⟩ => doc.dropRight 2
  | _ => panic! "Ill-formed module docstring."

def createMarkdownFile (title text : String) : IO FilePath := do
  let mdFile := markdownDir / (title ++ ".md")
  IO.FS.writeFile mdFile text
  return mdFile

def runPandoc (mdFile : FilePath) : IO FilePath := do
  unless (← mdFile.pathExists) && mdFile.extension = some "md" do
    IO.throwServerError s!"The file {mdFile} is not a valid Markdown file."
  unless mdFile.parent = some markdownDir do
    IO.throwServerError s!"The file {mdFile} is not in the `md` directory."
  
  let htmlFile : FilePath := slidesDir / (mdFile.fileStem.get! ++ ".html")
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

section Widget

structure HtmlRendererProps where
  htmlContent : String
deriving RpcEncodable

@[widget_module]
def HtmlRendererPanel : Component HtmlRendererProps where
  javascript := "
    import React from 'react';

    const e = React.createElement

    function HTMLRenderer(props) {
        return e('div', { dangerouslySetInnerHTML: { __html: props.htmlContent } });
      };

    export default function HTMLRendererPanel(props) {
      return (
        e('details', { open: true },
        e('summary', { className: 'mv2 pointer' }, 'Rendered HTML'),
        HTMLRenderer(props))
        );
    };
    "

#html <HtmlRendererPanel htmlContent={"<h1>Hello, this is HTML content!</h1><p>It will be rendered using React.</p>"} />

end Widget


syntax (name := slides) "#slides" ident moduleDoc : command

@[command_elab slides]
def revealSlides : CommandElab
  | stx@`(command| #slides $title $doc) => do
      let content := extractModuleDocContent doc
      let name := title.getId.toString
      let mdFile ← createMarkdownFile name content
      let htmlFile ← runPandoc mdFile
      IO.println s!"Rendering results for {name} ..."
      let slidesUrl := "file://" ++ (← IO.FS.realPath htmlFile).toString
      let slideContents ← IO.FS.readFile htmlFile
      IO.println slidesUrl
      let slides := Html.ofTHtml <HtmlRendererPanel htmlContent={slideContents} />
      runTermElabM fun _ ↦ do 
        savePanelWidgetInfo stx ``HtmlDisplayPanel do
          return json% { html : $(← rpcEncode slides) }
  | _ => throwUnsupportedSyntax

#slides test /-!
# Test slides

$$\sum_{i = 0}^n i^2 = \infty$$

# Last slide

Done.
-/
