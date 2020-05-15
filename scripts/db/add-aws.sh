dir=$(dirname $0)

roles="aws-dev aws-dev-full aws-dba aws-hotel"
prod="mysql.prod.infra.tstllc.net"

echo -n db_username: 
read username
echo

echo -n db_password: 
read -s password
echo

function usage {
    echo "Usage: $exe -d (update database) -r (update roles)"
}

update_databases=""
update_roles=""

while getopts ":dr" opt; do
    case $opt in
        d) 
            update_databases="true"
            ;;
        r) 
            update_roles="true"
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

function add_database {

    db=$1
    db_host=$2
    port=$3

    if [[ -n $update_databases ]] ; then
        $dir/add-database.sh -d $db -h $db_host -u $username -n $port -p $password $roles
    fi

    if [[ -n $update_roles ]] ; then
        for role in $roles ; do
            $dir/add-role.sh -d $db -r $role 
        done
    fi
}

add_database prod $prod 3306
