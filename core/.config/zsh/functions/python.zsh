# python venv
function sv() {
    if [[ $(dirname "$VIRTUAL_ENV") = "$PWD" ]]; then
        echo "Virtual environment already activated."
    else
        if [[ -n "$VIRTUAL_ENV" ]]; then
            echo "Deactivating virtual environment..."
            deactivate
        fi
        if [[ ! -d venv ]]; then
            echo "Creating new virtual environment..."
            python -m venv venv
        fi
        echo "Activating virtual environment..."
        source venv/bin/activate
    fi

    if ! pip freeze | grep -q python-lsp-server; then
        echo "Installing python-lsp-server..."
        pip install python-lsp-server
    fi


    if ! pip freeze | grep -q pylsp-mypy; then
        echo "Installing pylsp-mypy..."
        pip install pylsp-mypy
    fi

    if ! pip freeze | grep -q mypy; then
        echo "Installing mypy..."
        pip install mypy
    fi
}
