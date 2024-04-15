docker build . -f Dockerfile.fedora -t thinkmay && docker run -v .:/copy thinkmay

# yum install boost-filesystem-1.74.* \
#             boost-locale-1.74.* \
#             boost-log-1.74.* \
#             boost-program-options-1.74.* \
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