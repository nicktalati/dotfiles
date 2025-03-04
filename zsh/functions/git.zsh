function gn() {
    if [[ $# -ne 1 ]]; then
        echo "Name a nicktalati repo to pull."
        return 1
    fi
}
