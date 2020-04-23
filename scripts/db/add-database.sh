
function usage {
    echo "Usage: $exe -d <database> -h <host> -n <port> -u <user> -p <password> [-x <prefix>] <roles>..."
}

database=""
host=""
port="3306"
user="root"
password=""
prefix=""

while getopts ":d:h:n:u:p:x:" opt; do
    case $opt in
        d) 
            database="$OPTARG"
            ;;
        h) 
            host="$OPTARG"
            ;;
        n)
            port="$OPTARG"
            ;;
        u)
            user="$OPTARG"
            ;;
        p)
            password="$OPTARG"
            ;;
        x)
            prefix="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            ;; 
    
        :)
            echo "Option -$OPTARG requires an argument" >&2
            ;;
    esac 
done

shift $((OPTIND-1))

if [[ -z $database || -z $host || -z $password ]] ; then
    usage
    exit 1
fi


roles=""
for role in "$@" ; do
    if [[ -n $roles ]] ; then
        roles="$roles,"
    fi
    if [[ -n $prefix ]] ; then
        roles="${roles}${prefix}-"
    fi
    roles="${roles}${database}-${role}"
done

plugin="mysql-database-plugin"
# plugin="mysql-legacy-database-plugin"
opts=""
# opts="-output-curl-string"

set -x
vault write $opts database/config/$database \
    plugin_name=$plugin \
    connection_url="{{username}}:{{password}}@tcp(${host}:${port})/" \
    allowed_roles="$roles" \
    username="$user" \
    password="$password"
