# I ended up using this in a couple tools - so, I gave it its own library

# This got a little complicated. But, it works well ansd should be reuseable.
# I didn't put a check in here to ensure that every data row is of the same length as the header.
# But they should be - or else weirdness will ensue
def pp_table(header,data)
    row_prefix    = "| "
    row_suffix    = " |"
    col_join      = " | "
    header_colsep = "-+-"
    colsep_prefix = "+-"
    colsep_suffix = "-+"
    table_corner  = "+"

    # This is a quick way to calculate each column of the data's max string-width:
    array_col_widths = ([header]+data).inject(Array.new(header.length,0)){|ret,row|
       row.each_with_index{|f,i| ret[i] = f.length if f.to_s.length > ret[i] }
       ret
    }

    col_sprintf = row_prefix+array_col_widths.collect{|w| "%-#{w}s" }.join(col_join)+row_suffix

    table_width = (
      array_col_widths+[
        (array_col_widths.length-1)*col_join.length,
        row_prefix.length,
        row_suffix.length
      ]
    ).reduce(:+)

    table_ends = [table_corner,"-" * (table_width-table_corner.length*2),table_corner].join

    puts [
      table_ends,                        # Table-top
      col_sprintf % header,              # Header row
      [                                  # Header/data Separator
        colsep_prefix,
        array_col_widths.collect{|w| "-" * w}.join(header_colsep),
        colsep_suffix
      ].join,
      data.collect{|a| col_sprintf % a}, # Data rows
      table_ends,                        # Table-bottom
    ].flatten.join("\n")
end

def humanize_bool(v)
  v ? "Yes" : "No"
end
