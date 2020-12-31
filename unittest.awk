@include "csv2awk.awk"
BEGIN{
  FILE_ERR_COUNT = 0
  TEST_COUNT = 0
}
BEGINFILE {
  if ( ( FILENAME in SEEN ) || ( FILENAME !~ /[.]csv$/ ) ){
    nextfile
  }
  DAT_FILE = gensub( /[.]csv$/, ".dat", 1, FILENAME )
  SEEN[ FILENAME ] = 1
  TEST_NAME = ""
  FS = "\t"
  LINE = 1
  split( "", EXPECTED )
  while ( ( getline < DAT_FILE ) > 0 ){
    if ( ! TEST_NAME ){
      TEST_NAME = $0
      continue
    }
    for ( I = 1 ; I <= NF ; I++ ){
      EXPECTED[ LINE, I - 1 ] = $I
    }
    LINE++
  }
  close( DAT_FILE )
  ERR_COUNT = 0
  TEST_COUNT++
}
{
  csv_split(",")
  if ( NF != EXPECTED[ FNR, 0 ] ){
    print "ERROR: File " FILENAME " Line " FNR " Expected line size " EXPECTED[ FNR, 0 ] " Found " NF
    ERR_COUNT++
  }
  for ( I = 1 ; I <= NF ; I++ ){
    VALUE = gensub( /\n/, "\\\\n", "g", $I )
    gsub( /\t/, "\\\\t", VALUE )
    if ( EXPECTED[ FNR, I ] != VALUE ){
      print "ERROR: File " FILENAME " Line " FNR " Field " I " Expected value " EXPECTED[ FNR, I ] " Found " VALUE
      ERR_COUNT++
    }
  }
}
ENDFILE {
  if ( ! ERR_COUNT ){
    printf( "Test %-32.32s OK\n", TEST_NAME )
  } else {
    printf( "Test %-32.32s FAILED (%d errors)\n", TEST_NAME, ERR_COUNT )
    FILE_ERR_COUNT++
  }
}
END {
  print "---"
  print "Tests OK     " ( TEST_COUNT - FILE_ERR_COUNT ) "/" TEST_COUNT
  print "Tests FAILED " ( FILE_ERR_COUNT ) "/" TEST_COUNT
}
