#!/bin/bash



if  [[ $1 =~ ^/$ ]]; then
    echo "[-] no no no I wont delete THAT"
else
    echo "[+] this is fine"
fi

exit


IP_REGEX="[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(:[0-9]{1,5})?" # (\:[0-9]{1,5})"

if [[ $1 =~ $IP_REGEX ]]; then
    echo "yup, this is an ip address"
else
    echo "nope, not an ip address"
fi

test_func() {
    echo "but here $1 is something different"
}

test_func "dada"

exit


IFS=',' read -ra arr <<< $"$1"

echo "params: $#"

# arr=(un deux trois)
echo "arr: ${arr[*]}"

echo "count: ${#arr[@]} "

echo "done \\o/"

echo "${derp:?}"
