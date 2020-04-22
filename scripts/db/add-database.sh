if [[ -z $6 ]] ; then
    echo "Usage: $0 <database> <host> <port> <user> <password> <roles>..."
    exit 1
fi
database=$1
host=$2
port=$3
user=$4
password="$5"
shift 5

roles=""
for role in "$@" ; do
    if [[ -n $roles ]] ; then
        roles="$roles,"
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
