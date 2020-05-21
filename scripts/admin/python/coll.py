from collections import defaultdict

# Used to check unused parameter at its default
Unset = {}

not_none = lambda x: x is not None

# name1=value1,name2=value3,name3=val1|val2|val3
def string_to_map_list(val, nv_delim='=', pair_delim=',', val_delim='|'):
    return { e[0]: e[1].split(val_delim) for e in ( a.split(nv_delim) for a in val.split(pair_delim) ) }
 
def string_to_map(val, nv_delim='=', pair_delim=','):
    return { e[0]: e[1] for e in ( a.split(nv_delim) for a in val.split(pair_delim) ) }
 
def string_to_set(val, nv_delim='=', pair_delim=','):
    return { (e[0],e[1]) for e in ( a.split(nv_delim) for a in val.split(pair_delim) ) }
 
def string_to_tuples(val, nv_delim='=', pair_delim=','):
    return [ (e[0],e[1]) for e in ( a.split(nv_delim) for a in val.split(pair_delim) ) ]

def string_to_list(val, delim=','):
    return val.split(delim) if val else None
  
def first( c ):
    return next( iter(c), None ) if c else None

def first_match( c, matcher ):
    return find( c, matcher )

def first_elem( c, trans, matcher=not_none ):
    if c:
        for e in c:
            t = trans(e)
            if matcher(t): return t
    return None

def find( c, matcher ):
    if c:
        for e in c:
            if matcher(e): return e
    return None     

def ensure_field( obj, name ):
    x = obj.get( name )
    if not x: x = obj[name] = {}
    return x

def get_field( obj, name ):
    return obj.get(name) if obj else None

def get_sub_field( obj, sub, name ):
    x = obj.get( owner )
    return x.get( name ) if x else None

def set_sub_field( obj, sub, name, value ):
    ensure_field(obj,sub)[name] = value
       
def get_or_set( obj, name, value ):
    if value is Unset:
        return obj.get(name)
    else:
        obj[name] = value


def ensure( c ):
    return c if is_collection(c) else [ c ]

def is_collection( c ): return isinstance(c,(list,tuple,set)) and not isinstance(c,str)

def flatten( val, trans ):
    if is_collection(val):
        ret = []
        for v in val:
            ret.extend( trans(v) )
        return ret        
    else:
        return trans(val)

def group_by( cs, keyer ):
    ret = defaultdict(set)
    for c in cs:
        key = keyer(c)
        ret[key].add( c )
    return ret

def group_by_iter( cs, keyer ):
    ret = defaultdict(set)
    for c in cs:
        for key in keyer(c):
            ret[key].add( c )
    return ret


def chunks(l, n):
    for i in range(0, len(l), n):
        yield l[i:i + n]

def strip( lst, stripper ):
    """
    Removes elements from a collection based upon the result of stripper which returns a 
    number of elements to remove. This is useful for removing command line arguments that
    may have additional parameters.
    """
    ret = []
    cnt = 0
    for v in lst:
        cnt += stripper( v ) 
        if cnt == 0: 
            ret.append( v )
        elif cnt > 0:
            cnt -= 1
            
    return ret

def iter_pairs( ps ):
    """
        Will iterate through a dict, list of k,v tuples, or a list of k=v strings
    """
    if ps:
        if isinstance(ps,dict):
            for k,v in ps.items():
                yield (k,v)
        elif is_collection(ps):
            for p in ps:
                if isinstance(p,tuple):
                    yield p
                else:     
                    if '=' in p:
                        sp = p.split('=', 1)
                        if len(sp) == 2:    
                            yield (sp[0],sp[1]) 
                        else:
                            yield (sp[0],None)  
                    else:
                        raise Exception( "Invalid pair: {}".format(sp) )        


"""
Traverse an iterable in pairs of (elem[n],elem[n+1])...
"""
def iter_duos( iter ):
    prior = None
    for elem in iter:
        if prior:
            yield (prior, elem)
        prior = elem

def squish( dct ):
    ret = dict()

    def _squish(path, obj):
        if isinstance(obj,dict):
            for k, v in obj.items():
                _squish( (path + "." if path else "") + k, v )
        elif isinstance(obj, list):
            for i, item in enumerate(obj):
                _squish( "{}[{}]".format(path,i), item )
        else:
            if isinstance(obj,bool):
                ret[path] = ("true" if obj else "false")
            else:    
                ret[path] = obj

    _squish( "", dct )
    return ret

class keydefaultdict(defaultdict):
    def __missing__(self, key):
        if self.default_factory is None:
            raise KeyError( key )
        else:
            ret = self[key] = self.default_factory(key)
            return ret
