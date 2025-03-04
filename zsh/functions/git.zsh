function gn() {
    if [[ $# -ne 1 ]]; then
        echo "Name a nicktalati repo to clone."
        return 1
    fi
    git clone "git@github.com:nicktalati/$1.git"
    cd $1
}
