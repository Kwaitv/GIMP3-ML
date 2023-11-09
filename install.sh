#!/usr/bin/bash
# note this is to setup GIMP-ML for archlinux
echo "Installing GIMP-ML"

echo "checking for aur helper"
aur_helper=
paru_state=$(which paru 1>/dev/null 2>/dev/null;echo $?)
yay_state=$(which yay 1>/dev/null 2>/dev/null;echo $?)
if [ $paru_state -eq 0 ]
then
  aur_helper=paru
elif [ $yay_state -eq 0 ]
then
  aur_helper=yay
elif [ $(($paru_state + $yay_state)) -gt 1 ]
then
  echo Please use an Aur helper or read throug the script to install relevant pacakges
  exit 1;
fi

requirements=$(cat requirements.txt | sed 's/^/python-/g')

cpu=0

if [[ $cpuonly -eq 1 ]]
then
    requirements="${requirements} python-torchvision python-pytorch python-torchaudio"
else
    requirements="${requirements} python-pytorch-opt-cuda python-torchvision-cuda python-torchaudio"
fi

echo installing python modules
#$aur_helper $requirements

echo generating plugin config
python gimpml/init_config.py
mv 'gimpml\gimpml_config.json' gimpml/gimpml_config.json

echo verifying gimp

gimp_version=$(gimp --version | awk '{print $NF}')
min_ver="2.99.12"
ver_list="$gimp_version
$min_ver"
lower=$(sort <<< $ver_list | tail -n1)


if [ -z "$gimp_version" ]
then
    echo "No Gimp installed"
    exit 1
elif [ "$lower" != "$gimp_version" ]
then
    echo "A Newer Gimp Version Required"
    exit 1
fi

plugin_path=$(sed 's/\//\\\//g'<<<"$PWD/gimpml")
config_path="$HOME/.config/GIMP/$(awk -F. '{print $1"."$2}' <<<$gimp_version)"
echo $plugin_path
echo $config_path

sed -i 's/\(^(plug-in-path.*\))/\1:'$plugin_path')/g' "$config_path/gimprc"

