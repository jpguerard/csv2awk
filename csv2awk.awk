# csv2awk.awk - CSV-file processing with Gawk 4.0+
#
# Written in 2020 by Jean-Philippe Guérard <jean-philippe.guerard@tigreraye.org>
#
# To the extent possible under law, the author(s) have dedicated all
# copyright and related and neighboring rights to this software to the
# public domain worldwide. This software is distributed without any
# warranty.
#
# The full license text is available on <http://creativecommons.org/publicdomain/zero/1.0/>.
#
# Usage:
#
# @include "csv2awk.awk"
# { csv_split( "," ) }
# ... processing ...
# { print csv_convert( "," ) }
#
function csv_split( CSV_SEPARATOR,    FIELD_PATTERN, NB, SPLIT_LINE, IS_FIELD_COMPLETE, I, J, CSV_LINE, OLD_OFS, OLD_FNR ){
  OLD_FNR = FNR
  if ( CSV_SEPARATOR == "" ) { CSV_SEPARATOR = "," }
  FIELD_PATTERN = "([^" CSV_SEPARATOR "]*)|(\"([^\"]|\"\")+(\"|$))"
  # Split the CSV line into CSV_LINE
  I = 1
  split( "", CSV_LINE )
  while( 1 ) {
    sub( /\r$/, "" )
    NB = patsplit( $0, SPLIT_LINE, FIELD_PATTERN )
    for ( J = 1 ; J <= NB ; J++ ){
      IS_FIELD_COMPLETE = 0
      if ( I in CSV_LINE ) {
        CSV_LINE[ I ] = CSV_LINE[ I ] CSV_SEPARATOR SPLIT_LINE[ J ]
      } else {
        CSV_LINE[ I ] = SPLIT_LINE[ J ]
      }
      if ( CSV_LINE[ I ] ~ /^"([^"]|"")+"$/ ){
        CSV_LINE[ I ] = substr( CSV_LINE[ I ], 2, length( CSV_LINE[ I ] ) - 2 )
        IS_FIELD_COMPLETE = 1
        I++
      } else if ( CSV_LINE[ I ] ~ "^[^" CSV_SEPARATOR "\"]*$" ) {
        IS_FIELD_COMPLETE = 1
        I++
      }
    }
    if ( IS_FIELD_COMPLETE ) break
    if ( getline <= 0 ) break
    $0 = CSV_LINE[ I ] "\n" $0
    delete CSV_LINE[ I ]
  }
  # Rebuilding of the line with NULL separator
  NF = 0
  OLD_OFS = OFS
  OFS = FS ="\0"
  for ( I = 1 ; I <= length( CSV_LINE ) ; I++ ){
    $I = gensub( /""/, "\"", "g", CSV_LINE[ I ] )
  }
  OFS = OLD_OFS
  FNR = OLD_FNR
}
function csv_convert( CSV_SEPARATOR,    CSV_LINE, CSV_FIELD, MUST_ESCAPE ){
  if ( CSV_SEPARATOR == "" ) { CSV_SEPARATOR = "," }
  MUST_ESCAPE = "[\n\"" CSV_SEPARATOR "]"
  for ( I = 1 ; I <= NF ; I++ ){
    if ( $I ~ MUST_ESCAPE ){
      CSV_FIELD = "\"" gensub( /"/, "\"\"", "g", $I ) "\""
    } else {
      CSV_FIELD = $I
    }
    if ( CSV_LINE ){
      CSV_LINE = CSV_LINE CSV_SEPARATOR CSV_FIELD
    } else {
      CSV_LINE = CSV_FIELD
    }
  }
  return CSV_LINE
}
