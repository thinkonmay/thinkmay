cd webrtc; go build -o ..\..\assets\proxy.exe .\cmd\; cd ..
cd daemon; go build -o ..\..\assets\daemon.exe .\cmd\; cd ..
cd daemon; go build -o ..\..\assets\pb.exe .\pocketbase\cmd\; cd ..
cd daemon; go build -o ..\..\assets\microphone.exe .\microphone\cmd\; cd ..
cd steam; dotnet publish --sc true -o ../../assets/store /p:PublishSingleFile=true . ; cd ..
cd sunshine/build; ninja; cp sunshine.exe ..\..\..\assets\shmsunshine.exe; cd ../..
