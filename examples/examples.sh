SPINNERS_FILE="$HOME/.config/spinner/spinners.json"   # Default location of spinners file.

keys=$(jq -r 'keys' "$SPINNERS_FILE")
if [[ "$keys" = "null" ]]; then
    (>&2 echo "$0: Was unable to load spinners for $SPINNERS_FILE.")
    exit 1
fi

readarray -t spinners <<< $(echo "$keys" | tr -d " ,[]" | sort | tail -c +3 )

trap 'exit' SIGINT

for key in "${spinners[@]}"; do
    ../spinner.sh -s "$key" eval "echo -ne \"\t\t\t$key\" && sleep 3"
done
