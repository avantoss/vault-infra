dir=$(dirname $0)

roles="full write readonly"
password="kube-aws"

lower="nodes.lower.kube.tstllc.net"
nonprod="nodes.nonprod.kube.tstllc.net"


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
    cluster=$2
    port=$3

    if [[ -n $update_databases ]] ; then
        $dir/add-database.sh -x lowers -d $db -h $cluster -n $port -p $password $roles
    fi

    if [[ -n $update_roles ]] ; then
        for role in $roles ; do
            $dir/add-role.sh -x lowers -d $db -r $role 
        done
    fi
}

add_database qa $lower 32100
add_database dev $lower 32110
add_database staging $lower 32120

add_database uat $nonprod 32112
add_database cdev $nonprod 32114
add_database cstaging $nonprod 32116
add_database client $nonprod 32110
add_database pfix $nonprod 32118
