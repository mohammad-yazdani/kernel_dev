if [[ ! -f ubuntu-focal ]]; then
    git clone git://kernel.ubuntu.com/ubuntu/ubuntu-focal.git
    cd ubuntu-focal
    git checkout Ubuntu-5.4.0-72.80
    cd ..
fi
cd ubuntu-focal
LANG=C fakeroot debian/rules clean
LANG=C fakeroot debian/rules binary-headers binary-generic binary-perarch
