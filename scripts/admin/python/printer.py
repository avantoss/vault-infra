import sys
import logging

log = logging.getLogger( "printer" )

def write( headers, rows, out=sys.stdout, delim='|' ):
    all = []
    all.append( headers )
    all.extend( rows )

    for r, row in enumerate(all):
        for c, col in enumerate(row):
            if col is None:
                raise Exception( "Found None [{}][{}] : {}".format(r,c,row) )


    def justify( val, col ):
        return str(val).ljust(widths[col]) 

    def print_row(row):
        cols = (justify(col,i) for i, col in enumerate(row) )
        if delim:
            print('| ' + ' | '.join(cols) + ' |', file=out)
        else:      
            print(" ".join(cols), file=out)

    count = len(headers)
    widths = [max(len(str(r[i])) for r in all) for i in range(0, count)]

    print_row(headers)
    print_row(('-'*width for width in widths))

    for row in rows:
        print_row(row)

def dicts_to_lists( attrs, rows ):
    ret = []
    for row in rows:
        ret.append( [row[a] for a in attrs] )

    return ret    

