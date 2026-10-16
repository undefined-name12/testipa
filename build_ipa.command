#!/usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"
bash "$DIR/build_ipa.sh"
read -p "Presiona ENTER para cerrar..."
