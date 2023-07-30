import Lake
open Lake DSL

package «leanRevealSlides» {
  precompileModules := true
}

@[default_target]
lean_exe «leanRevealSlides» {
  root := `«LeanRevealSlides»
}

require proofwidgets from git "https://github.com/EdAyers/ProofWidgets4" @ "v0.0.13"