#!/usr/bin/env julia

import REPL: REPLCompletions

const snipmate_dir = "snippets"
const snipmate_filename = "_.snippets"
const ultisnips_dir = "UltiSnips"
const ultisnips_filename = "all_unicode.snippets"
const vscode_dir = "vsnip"
const vscode_filename = "unicode_availables.json"

abstract type SnippetProtocol end

function _genprotocol(protocol_name)
  sniptype = esc(protocol_name)
  basetype = esc(:SnippetProtocol)
  quote
    struct $sniptype <: $basetype
      path::String
      io::IO
      function $sniptype(path::String)
        io = open(path, "w")
        new(path, io)
      end
    end

    function Base.close(snip::$sniptype)
      close(snip.io)
    end
  end
end

macro genprotocol(protocol_names::Symbol...)
  Expr(:block, (_genprotocol(name) for name in protocol_names)...)
end

@genprotocol SnipMate UltiSnips VSnip

function add_snippet(snip::SnipMate, keyword::String, unicode::String)
  println(snip.io, "snippet $keyword $unicode")
  println(snip.io, "\t$unicode")
end

function add_snippet(snip::UltiSnips, keyword::String, unicode::String)
  println(snip.io, "snippet $keyword \"$unicode\" i")
  println(snip.io, unicode)
  println(snip.io, "endsnippet")
end

function add_snippet(snip::VSnip, keyword::String, unicode::String)
  println(snip.io, "  \"\\$keyword\": {")
  println(snip.io, "    \"prefix\": \"\\$keyword\",")
  println(snip.io, "    \"body\": \"$unicode\",")
  println(snip.io, "    \"description\": \"$unicode\"")
  println(snip.io, "  },")
end

function add_header(snip::T, cmtstr::String) where {T<:SnippetProtocol}
  if typeof(snip) == VSnip
    println(snip.io, '{')
  else
    println(snip.io, "$cmtstr This file was generated by `$(basename(Base.source_path()))`")
    println(snip.io, "$cmtstr using Julia $VERSION")
  end
end

function Base.close(snip::VSnip)
  pos = position(snip.io)
  seek(snip.io, pos - 2)
  truncate(snip.io, pos - 2)
  println(snip.io, "\n}")
  close(snip.io)
end

function main()
  mkpath(snipmate_dir)
  mkpath(ultisnips_dir)
  mkpath(vscode_dir)

  snipmate = SnipMate(joinpath(snipmate_dir, snipmate_filename))
  ultisnips = UltiSnips(joinpath(ultisnips_dir, ultisnips_filename))
  vsnip = VSnip(joinpath(vscode_dir, vscode_filename))

  add_header(snipmate, "#")
  add_header(ultisnips, "#")
  add_header(vsnip, "//")

  for (keyword, unicode) in sort!(collect(Iterators.flatten(
      (REPLCompletions.latex_symbols,
      REPLCompletions.emoji_symbols))),
    by=x -> x[2])
    for snip in (snipmate, ultisnips, vsnip)
      add_snippet(snip, keyword, unicode)
    end
  end

  for snip in (snipmate, ultisnips, vsnip)
    close(snip)
  end
end

main()
