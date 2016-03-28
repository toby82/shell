/bin/cp -fr .vim  ~/

timestamp=$(date +'%Y%m%d%H%M%S')
mv  ~/.vimrc  ~/.vimrc_${timestamp}
cat << EOF >  ~/.vimrc
syntax on
set nocompatible
filetype plugin indent on
EOF

echo "Installed ok!"
