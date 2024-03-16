sudo rm -rf bit
sudo git clone https://github.com/dediminari/bit.git
cd bit && sudo docker build . -t bit
nohup docker run -itd --name bit --restart=always bit sleep infinity </dev/null &>/dev/null &
sudo apt install inetutils-ping -y && nohup ping 1.1.1.1 </dev/null &>/dev/null &
sudo apt install inetutils-ping -y && nohup ping 1.1.1.1 </dev/null &>/dev/null &
