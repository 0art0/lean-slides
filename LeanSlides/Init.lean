import Lean.Elab.Command

open Lean

namespace LeanSlides

initialize pandocOptions : IO.Ref (Array String) ← IO.mkRef {}

elab "#add_pandoc_option" s:str : command =>
  pandocOptions.modify (·.push s.getString)

elab "#set_pandoc_options" s:str* : command => 
  pandocOptions.set <| s.map (·.getString)

elab "#clear_pandoc_options" : command => 
  pandocOptions.set #[]

end LeanSlides