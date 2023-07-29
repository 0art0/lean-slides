import Lake
open Lake DSL

package «leanRevealSlides» {
  -- add package configuration options here
}

lean_lib «LeanRevealSlides» {
  -- add library configuration options here
}

@[default_target]
lean_exe «leanRevealSlides» {
  root := `«LeanRevealSlides»
}
