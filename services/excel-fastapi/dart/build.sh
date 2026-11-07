#!/bin/sh
# スキルシートのコマンドを作る（Dockerfile・CI で使う）
#   sh dart/build.sh <frontend のフォルダー> <出力するファイル（絶対パス）>
# frontend の lib/・bin/ を、Flutter なしの pubspec（dart/pubspec.yaml）と一緒に別の場所に写して dart compile exe する
set -eu
frontend=$1
out=$2
work=$(mktemp -d)
cp -R "$frontend/lib" "$frontend/bin" "$work/"
cp "$(dirname "$0")/pubspec.yaml" "$work/pubspec.yaml"
mkdir -p "$(dirname "$out")"
cd "$work"
dart pub get
dart compile exe bin/skill_sheet.dart -o "$out"
rm -rf "$work"
