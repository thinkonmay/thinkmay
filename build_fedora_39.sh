docker build . -f Dockerfile.fedora -t thinkmay && docker run -v ./out:/copy thinkmay
cp -r out/binary/* binary 

# yum install boost-filesystem-1.81.0 \
#             boost-locale-1.81.0 \
#             boost-log-1.81.0 \
#             boost-program-options-1.81.0 \
#             libcap  \
#             libcurl  \
#             libdrm   \
#             libevdev   \
#             libopusenc   \
#             libva   \
#             libvdpau  \
#             libwayland-client   \
#             libX11   \
#             miniupnpc   \
#             numactl-libs   \
#             openssl   \
#             pulseaudio-libs  