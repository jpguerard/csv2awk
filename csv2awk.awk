# csv2awk.awk - CSV-file processing with Gawk 4.0+
#
# (c) 2020-2022 Jean-Philippe Guérard <jean-philippe.guerard@tigreraye.org>
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

function csv_convert(csv_sep, csv_line, csv_field, must_escape, i)
{
	if (csv_sep == "") {
		csv_sep = ","
	}
	must_escape = "[\n\"" csv_sep "]"
	for (i = 1; i <= NF; i++) {
		if ($i ~ must_escape) {
			csv_field = "\"" (gensub(/"/, "\"\"", "g", $i)) "\""
		} else {
			csv_field = $i
		}
		if (csv_line) {
			csv_line = csv_line csv_sep csv_field
		} else {
			csv_line = csv_field
		}
	}
	return csv_line
}

function csv_split(csv_sep, field_pattern, n, t_split_line, is_field_complete, i, j, t_csv_line, old_fnr)
{
	old_fnr = FNR
	if (csv_sep == "") {
		csv_sep = ","
	}
	field_pattern = "([^" csv_sep "]*)|(\"([^\"]|\"\")+(\"|$))"
	# Split the CSV line into t_csv_line
	i = 1
	split("", t_csv_line, FS)
	while (1) {
		sub(/\r$/, "", $0)
		n = patsplit($0, t_split_line, field_pattern)
		for (j = 1; j <= n; j++) {
			is_field_complete = 0
			if (i in t_csv_line) {
				t_csv_line[i] = t_csv_line[i] csv_sep t_split_line[j]
			} else {
				t_csv_line[i] = t_split_line[j]
			}
			if (t_csv_line[i] ~ /^"([^"]|"")+"$/) {
				t_csv_line[i] = substr(t_csv_line[i], 2, length(t_csv_line[i]) - 2)
				is_field_complete = 1
				i++
			} else if (t_csv_line[i] ~ ("^[^" csv_sep "\"]*$")) {
				is_field_complete = 1
				i++
			}
		}
		if (is_field_complete) {
			break
		}
		if ((getline) <= 0) {
			break
		}
		$0 = t_csv_line[i] "\n" $0
		delete t_csv_line[i]
	}
	# Rebuilding the line
	NF = 0
	for (i = 1; i <= length(t_csv_line); i++) {
		$i = gensub(/""/, "\"", "g", t_csv_line[i])
	}
	FNR = old_fnr
}
