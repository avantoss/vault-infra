dir=$(dirname $0)

teams="air car hotel cruise"

for team in $teams ; do
    $dir/team-policy.sh $team
done
