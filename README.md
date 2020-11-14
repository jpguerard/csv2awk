# csv2awk
A small library to process CSV files with Gawk

CSV files are difficult to process with Gawk. Since version 4.0,
Gawk offers a nice functionality to read CSV files: the
[FPAT](https://www.gnu.org/software/gawk/manual/html_node/Splitting-By-Content.html),
variable. `FPAT` will split fields depending on their content,
instead  of splitting the fields depending on separators. With this,
it is possible to correctly split a CSV line, provided it does not
include line breaks.

This small Gawk library offers 2 functions: `csv_split()` and
`csv_convert()`.

It offers the following benefits:
* Works in native Gawk, without requiring an external extension.
* Works with CSV fields including line breaks.
* Tested with LibreOffice and Excel CSV files.
* Can be used to change a CSV file with a simple Gawk program.

It has however some limitations:
* If a field contains a line break, it has to be between double
  quotes (this is only recommended by RFC 4180).
* As is, it only works with the standard input (e.g. not the
  explicitly open files, command and coprocess).
* It requires Gawk version 4.0 or more.
* After being processed by `csv_split()`, the line will be separated
  by `NULL` characters (ASCII 0) and `FS` will be set to `NULL`. This
  enables us to use functions that will force the line to be
  reevaluated (`sub`, `gsub`, `$0 = ...`) without the line being
  incorrectly split.
* As a corollary, if the original line contains `NULL` characters,
  a reevaluation of the line will split it incorrectly.

### csv_split()

The `csv_split()` function reads the current line (`$0`) and
translate it from CSV to a regular Gawk input line. The `csv_split()`
takes the CSV separator as a parameter (by default, a comma will be
used).

It splits the line according to the CSV fields and reads more input
lines (with `getline`). After splitting, the line is formatted as a
regular Gawk input line (`NF`, `$0`, `$1`, `$2`, ...), `NULL`-separated
and `FS` is set to `NULL`.

### csv_convert()

The `csv_convert()` function will return the current line formatted
as CSV. The `csv_convert()` takes the CSV separator as a parameter
(by default, a comma will be used).

It can be used after `csv_split()` to display the line as CSV. With
this, you can process a CSV file with Gawk the same way you would
process a regular text file.

But it can also be used in a regular Gawk script to convert the output
to CSV.

## Demo

### 1. display CSV fields

Let's export the following data as CSV:
```
-------------------------------------------
|   a   |   b   |   c   |  x y  | "x " y" |
-------------------------------------------
```

This gives us:
```csv
a,b,c,"x y","""x "" y"""
```

Let's save our library as `csv2awk.awk` and use it to read the CSV
file we just produced:

```sh
echo 'a,b,c,"x y","""x "" y"""' \
| gawk '@include "csv2awk.awk"
        { csv_split() ; for (I=1 ; I<=NF ; I++) { print I ": " $I } }'
```

This will give us back our original table:
```
1: a
2: b
3: c
4: x y
5: "x " y"
```

### 2. modifying a CSV file

This time, we will use Gawk to change the content of a CSV file. We
will use the same file as in the previous example:

```
a,b,c,"x y","""x "" y"""
```

As a simple test, we will replace all double quotes by underlines:

```sh
echo 'a,b,c,"x y","""x "" y"""' \
| gawk '@include "csv2awk.awk"
        { csv_split() ; gsub( /"/, "_" ) ; print csv_convert() }'
```

Which gives us the expected result:

```
a,b,c,x y,_x _ y_
