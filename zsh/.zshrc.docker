alias dockershell="docker run --rm -i -t --entrypoint=/bin/bash"

# run dockershell as current user and mount PWD
function dockershellhere() {
    dirname=${PWD##*/}
    docker run --rm -it \
        --entrypoint=/bin/bash \
        -v "$(pwd)":"/home/user/${dirname}" \
        -w "/home/user/${dirname}" \
        --net=none \
        --cap-drop=ALL \
        --security-opt="no-new-privileges=true" \
        --user $(id -u):$(id -g) \
        "$@"
}
