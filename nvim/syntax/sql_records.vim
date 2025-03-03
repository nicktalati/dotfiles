" Vim syntax file
" Language: SQL Records
" Maintainer: Your Name
" Last Change: YYYY-MM-DD

if exists("b:current_syntax")
  finish
endif

syn match sqlRecordDelimiter "^-\[.*\]-------------------------$"
syn match sqlRecordField "^\w\+\s*|"
syn match sqlRecordValue "|\s*\zs.*$"

hi def link sqlRecordDelimiter Comment
hi def link sqlRecordField Keyword
hi def link sqlRecordValue String

let b:current_syntax = "sqlrecords"
