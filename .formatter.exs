[
  line_length: 98,
  heex_line_length: 120,
  import_deps: [
    :union_typespec
  ],
  plugins: [],
  inputs: ["*.{ex,exs}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{ex,exs,heex}"],
  subdirectories: ["priv/*/migrations", "priv/repo/data_migrations"]
]
