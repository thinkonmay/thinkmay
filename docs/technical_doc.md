# Thinkmay CloudPC - Developer Documentation

## Overview
Thinkmay CloudPC is a high-performance cloud PC service designed to provide low-latency virtual desktop environments. The architecture emphasizes high availability, responsive streaming, and robust encoding pipelines.

## System Architecture

### Streaming & Network
* **Protocol**: WebRTC is the core streaming protocol, chosen for its real-time, low-latency characteristics.
* **Resilience**: Optionally supports FlexFEC (Flexible Forward Error Correction) and NACK + RTX (Negative Acknowledgment + Retransmission) to handle packet loss gracefully.
* **Congestion Control**: Utilizes Google Congestion Control (GCC) for adaptive bitrate streaming, ensuring smooth visual quality gracefully degrading under poor network conditions.
* **Routing**: Implements multi-routing to ensure a High Availability (HA) network topology for failover and optimal path selection.

### Video & Encoding Pipeline
* **Codecs Supported**: H.264, H.265 (HEVC).
* **Hardware Acceleration**: Video encoding is GPU accelerated for minimal processing latency and maximum frame throughput.

### Input & Client Support
* **Browser Compatibility**: Fully tested and supported on modern versions of Chrome and Safari.
* **Responsive Inputs**:
    * Full Touch and Multi-Touch support.
    * Native Gamepad and Virtual Gamepad integrations for gaming or advanced input requirements.
    * Microphone pass-through support.
    * Adaptive mobile and desktop clients layout.

## Infrastructure
* **Edge Locations**: Servers are currently provisioned in:
    * HCM (Ho Chi Minh City)
    * HP (Hai Phong)
* *Note: Ensure your deployment configs account for regional routing based on client IP proximity.*
