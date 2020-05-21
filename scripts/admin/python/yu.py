import textwrap
from io import StringIO
from ruamel.yaml import YAML
from ruamel.yaml.scalarstring import PreservedScalarString
import coll

def yaml_str( data ):
    io = StringIO()
    yaml_dump( data, io )
    s = io.getvalue().replace("\n\n","\n")
    io.close()
    return s

def yaml_dump( data, io ):
    yaml = YAML()
    yaml.default_flow_style = False
    yaml.preserve_quotes = True
    if coll.is_collection(data):
        yaml.dump_all(data,io)
    else:
        yaml.dump(data,io)

def block_string( s ):
    return PreservedScalarString( textwrap.dedent(s) ) 

def yaml_load_file( filename, validate=False ):
    with open(filename,"r") as fd:
        return yaml_load( fd, validate )

def yaml_load( yml, validate=False ):
    ret = YAML().load( yml )
    if validate: 
        if not ret:
            raise Exception( "Failed parsing yaml: {}".format(yml) )

    return ret

def yaml_load_all( yml, validate=False ):
    ret = list( YAML().load_all(yml) )
    if validate:
        for i,y in enumerate(ret):
            if not y:
                raise Exception( "Failed parsing yaml[{}]: {}".format(i,yml) )

    return ret

