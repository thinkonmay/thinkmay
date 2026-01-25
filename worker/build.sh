cd daemon 
go build -o ~/assets/daemon ./cmd 
go build -o ~/assets/pb     ./cmd/pocketbase 
cd ..

cd proxy 
go build -o ~/assets/proxy ./cmd 
cd ..

sudo systemctl restart proxy
sudo systemctl restart virtdaemon
tail -f ~/assets/thinkmay.log
