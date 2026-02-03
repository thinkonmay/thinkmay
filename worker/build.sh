cd daemon 
go build -o ~/assets/daemon ./cmd 
go build -o ~/assets/pb     ./cmd/pocketbase 
cd ..

cd proxy 
go build -o ~/assets/proxy ./cmd 
cd ..

scp ~/assets/proxy 192.168.1.8:~/assets/proxy.
scp ~/assets/pb 192.168.1.8:~/assets/pb.
scp ~/assets/daemon 192.168.1.8:~/assets/daemon.

sudo systemctl restart proxy
sudo systemctl restart virtdaemon
tail -f ~/assets/thinkmay.log
