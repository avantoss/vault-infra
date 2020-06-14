$(dirname $0)/role.sh -c builds -n jenkins -r jenkins -p builder,kube -a default,jenkins
$(dirname $0)/role.sh -c builds -n drone -r drone -p builder -a default
$(dirname $0)/role.sh -c builds -n vdrone -r vdrone -p builder -a default
