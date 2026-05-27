 Moonlight Frame Pacing Protocol

  Purpose

  Moonlight’s frame pacing system smooths video playback by delaying frames that arrive too early and dropping frames when the client falls behind. It is designed to reduce micro-stutter without adding
  unbounded latency.

  The relevant UI description is in app/gui/SettingsView.qml:846:

  ▎ “Frame pacing reduces micro-stutter by delaying frames that come in too early”

  This system mainly applies to the FFmpeg-based video path. The Steam Link / SLVideo path is more direct and does not use the same Pacer queueing model.

  ---
  High-level pipeline

  The FFmpeg video path looks roughly like this:

  Network decode unit
          |
          v
  Session::drSubmitDecodeUnit()
          |
          v
  FFmpegVideoDecoder::submitDecodeUnit()
          |
          v
  FFmpeg decoder thread
          |
          v
  Decoded AVFrame
          |
          v
  Pacer::submitFrame()
          |
          +-----------------------------+
          |                             |
          v                             v
   Pacing queue                  Direct render queue
   if frame pacing active        if pacing unavailable/disabled
          |
          v
  V-sync event
          |
          v
  Render queue
          |
          v
  Renderer::waitToRender()
          |
          v
  Renderer::renderFrame()
          |
          v
  Display

  Core files:

  - app/streaming/video/ffmpeg.cpp
  - app/streaming/video/ffmpeg.h
  - app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp
  - app/streaming/video/ffmpeg-renderers/pacer/pacer.h
  - app/streaming/video/ffmpeg-renderers/renderer.h

  ---
  When frame pacing is enabled

  Frame pacing is user-configurable and depends on V-sync.

  The settings UI enables the checkbox only when V-sync is enabled:

  enabled: StreamingPreferences.enableVsync
  checked: StreamingPreferences.enableVsync && StreamingPreferences.framePacing

  Reference: app/gui/SettingsView.qml:838

  The stored default is currently disabled:

  framePacing = settings.value(SER_FRAMEPACING, false).toBool();

  Reference: app/settings/streamingpreferences.cpp:139

  During stream setup, Moonlight passes frame pacing into decoder selection like this:

  enableVsync && m_Preferences->framePacing

  Reference: app/streaming/session.cpp:2194

  The FFmpeg decoder then creates a Pacer:

  m_Pacer = new Pacer(m_FrontendRenderer, &m_ActiveWndVideoStats);

  Reference: app/streaming/video/ffmpeg.cpp:499

  The pacer is initialized with pacing enabled if either:

  1. The user enabled frame pacing, or
  2. The renderer requires pacing while V-sync is enabled.

  params->enableFramePacing ||
  (params->enableVsync &&
   (m_FrontendRenderer->getRendererAttributes() & RENDERER_ATTRIBUTE_FORCE_PACING))

  Reference: app/streaming/video/ffmpeg.cpp:500

  ---
  Main frame queues

  The main pacing object is Pacer.

  It owns two frame queues:

  QQueue<AVFrame*> m_RenderQueue;
  QQueue<AVFrame*> m_PacingQueue;

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.h:59

  It also owns history queues:

  QQueue<int> m_PacingQueueHistory;
  QQueue<int> m_RenderQueueHistory;

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.h:61

  These history queues are important because Moonlight does not immediately treat every temporary queue spike as a problem. It uses recent queue history to distinguish between:

  - short bursts that resolve naturally
  - sustained backlog that requires frame dropping

  ---
  Maximum buffering

  Moonlight intentionally keeps the pacing buffer small.

  The pacer defines the maximum number of outstanding frames as:

  #define PACER_MAX_OUTSTANDING_FRAMES (3 + 1 + 1)

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.h:14

  The comment explains the budget:

  // - 3 frames in the pacing queue
  // - 1 frame removed from the render queue in the process of rendering
  // - 1 frame for deferred free

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.h:10

  So the FFmpeg pacer is not a large latency buffer. It is a small, low-latency smoothing layer.

  The pacer also limits each internal queue to 3 frames:

  #define MAX_QUEUED_FRAMES 3

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp:21

  If a queue is full when a new frame is added, the oldest frame is dropped:

  if (queue.size() == MAX_QUEUED_FRAMES) {
      AVFrame* frame = queue.dequeue();
      av_frame_free(&frame);
  }

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp:394

  ---
  Decoder interaction

  The FFmpeg decoder has a separate metadata queue:

  QQueue<DECODE_UNIT> m_FrameInfoQueue;

  Reference: app/streaming/video/ffmpeg.h:137

  This queue does not primarily smooth playback. It tracks decode-unit metadata while FFmpeg turns compressed input into decoded frames.

  When a decode unit is submitted, Moonlight sends the compressed packet into FFmpeg:

  err = avcodec_send_packet(m_VideoDecoderCtx, m_Pkt);

  Reference: app/streaming/video/ffmpeg.cpp:2077

  Then it stores the decode unit metadata:

  m_FrameInfoQueue.enqueue(*du);
  m_FramesIn++;

  Reference: app/streaming/video/ffmpeg.cpp:2104

  Later, when FFmpeg outputs a decoded frame, Moonlight pops the corresponding decode-unit metadata:

  DECODE_UNIT du = m_FrameInfoQueue.dequeue();

  Reference: app/streaming/video/ffmpeg.cpp:1919

  It uses this to measure decode latency and preserve presentation timing:

  frame->pts = (int64_t)du.rtpTimestamp;

  Reference: app/streaming/video/ffmpeg.cpp:1927

  The decoded frame is then passed into the pacer:

  m_Pacer->submitFrame(frame);

  Reference: app/streaming/video/ffmpeg.cpp:1933

  ---
  Hardware decoder surface budget

  Because the pacer may hold several decoded frames, Moonlight tells FFmpeg to allocate extra hardware frames:

  m_VideoDecoderCtx->extra_hw_frames = PACER_MAX_OUTSTANDING_FRAMES;

  Reference: app/streaming/video/ffmpeg.cpp:547

  This prevents the renderer/pacer from holding all available decoder surfaces and starving the decoder.

  This is important for hardware decode paths because decoded video frames may be backed by GPU surfaces rather than ordinary CPU memory.

  ---
  Pacer initialization

  The pacer records:

  - stream FPS
  - display refresh rate
  - renderer attributes

  m_MaxVideoFps = maxVideoFps;
  m_DisplayFps = StreamUtils::getDisplayRefreshRate(window);
  m_RendererAttributes = m_VsyncRenderer->getRendererAttributes();

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp:262

  If pacing is enabled, Moonlight tries to create a platform-specific V-sync source.

  On Windows:

  m_VsyncSource = new DxVsyncSource(this);

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp:284

  On Wayland:

  m_VsyncSource = new WaylandVsyncSource(this);

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp:290

  If no V-sync source exists, frames are rendered immediately instead of being paced.

  ---
  Submit-frame behavior

  When a decoded frame arrives, Pacer::submitFrame() decides where it goes.

  If a V-sync source exists:

  dropFrameForEnqueue(m_PacingQueue);
  m_PacingQueue.enqueue(frame);
  m_PacingQueueNotEmpty.wakeOne();

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp:410

  That means the frame waits in the pacing queue until a V-sync event.

  If no V-sync source exists:

  enqueueFrameForRenderingAndUnlock(frame);

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp:416

  That means the frame bypasses the pacing queue and goes directly to the render queue.

  ---
  V-sync-driven pacing

  The heart of the protocol is Pacer::handleVsync().

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp:201

  On every V-sync event, Moonlight:

  1. Looks at pacing queue history.
  2. Decides whether to be strict or lenient about frame drops.
  3. Drops frames if the queue is too deep.
  4. Moves one frame from the pacing queue to the render queue.

  ---
  Queue-history smoothing

  The pacer keeps a rolling 500 ms window of pacing queue sizes:

  if (m_PacingQueueHistory.count() == m_DisplayFps / 2) {
      m_PacingQueueHistory.dequeue();
  }

  m_PacingQueueHistory.enqueue(m_PacingQueue.count());

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp:225

  The algorithm starts strict:

  int frameDropTarget = 1;

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp:210

  But if recent history shows the queue has dropped to 1 frame or less, it becomes lenient:

  if (queueHistoryEntry <= 1) {
      frameDropTarget = 3;
      break;
  }

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp:216

  In plain English:

  - If the queue only spikes briefly, allow up to 3 queued frames.
  - If the queue has stayed deep for a while, reduce the target to 1 queued frame.
  - This avoids unnecessary frame drops during short bursts but catches up when latency is accumulating.

  ---
  Frame dropping during pacing

  After choosing a drop target, Moonlight drops old frames until the pacing queue is small enough:

  while (m_PacingQueue.count() > frameDropTarget) {
      AVFrame* frame = m_PacingQueue.dequeue();
      m_VideoStats->pacerDroppedFrames++;
      av_frame_free(&frame);
  }

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp:233

  This is how Moonlight avoids building up latency.

  The goal is not to show every decoded frame. The goal is to show the newest useful frame at the right time.

  ---
  Moving frames to the render queue

  Once the pacer has selected the next frame, it moves one frame to the render queue:

  enqueueFrameForRenderingAndUnlock(m_PacingQueue.dequeue());

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp:258

  The render queue is then consumed either by:

  - a dedicated render thread, or
  - the main thread, depending on renderer support.

  ---
  Render thread behavior

  If the renderer supports a render thread, Moonlight creates one:

  m_RenderThread = SDL_CreateThread(Pacer::renderThread, "PacerRender", this);

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp:320

  The render thread repeatedly:

  1. Waits until the renderer is ready.
  2. Waits for a queued frame.
  3. Dequeues a frame.
  4. Renders it.

  m_VsyncRenderer->waitToRender();

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp:149

  Then:

  AVFrame* frame = me->m_RenderQueue.dequeue();
  me->renderFrame(frame);

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp:166

  The waitToRender() hook is important because it lets the renderer avoid latching a new frame before the display pipeline is ready.

  ---
  Renderer-specific presentation control

  Different renderers implement presentation readiness differently.

  Vulkan / libplacebo

  The Vulkan renderer waits on swapchain presentation before selecting a new frame:

  pl_swapchain_swap_buffers(m_Swapchain);

  Reference: app/streaming/video/ffmpeg-renderers/plvk.cpp:792

  Then it starts the next swapchain frame:

  pl_swapchain_start_frame(m_Swapchain, &m_SwapchainFrame)

  Reference: app/streaming/video/ffmpeg-renderers/plvk.cpp:809

  EGL / OpenGL

  The EGL renderer waits on a sync fence if available:

  m_eglClientWaitSync(..., EGL_FOREVER);

  Reference: app/streaming/video/ffmpeg-renderers/eglvid.cpp:729

  Otherwise it falls back to:

  glFinish();

  Reference: app/streaming/video/ffmpeg-renderers/eglvid.cpp:735

  VDPAU

  VDPAU waits for the next output surface to become idle:

  m_VdpPresentationQueueBlockUntilSurfaceIdle(...)

  Reference: app/streaming/video/ffmpeg-renderers/vdpau.cpp:523

  ---
  Render queue backlog handling

  Moonlight also monitors the render queue after each rendered frame.

  In Pacer::renderFrame(), it records render queue history and decides whether queued frames should be dropped.

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp:351

  If the renderer declares that it does not buffer frames internally:

  if (m_RendererAttributes & RENDERER_ATTRIBUTE_NO_BUFFERING)

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp:356

  Moonlight allows one queued frame to avoid starving presentation:

  frameDropTarget = 1;

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp:359

  Otherwise, it uses render queue history. If the render queue has recently drained to zero, it is lenient and allows up to 2 queued frames:

  if (queueHistoryEntry == 0) {
      frameDropTarget = 2;
      break;
  }

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp:363

  If backlog persists, it drops frames:

  while (m_RenderQueue.count() > frameDropTarget) {
      AVFrame* frame = m_RenderQueue.dequeue();
      m_VideoStats->pacerDroppedFrames++;
      av_frame_free(&frame);
  }

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp:380

  ---
  Renderer attributes

  Renderers communicate pacing requirements through flags:

  #define RENDERER_ATTRIBUTE_NO_BUFFERING 0x08
  #define RENDERER_ATTRIBUTE_FORCE_PACING 0x10

  Reference: app/streaming/video/ffmpeg-renderers/renderer.h:137

  For example, the DRM renderer says it does not buffer frames in the graphics pipeline:

  attributes |= RENDERER_ATTRIBUTE_NO_BUFFERING;

  Reference: app/streaming/video/ffmpeg-renderers/drm.cpp:1005

  The D3D11VA renderer can force pacing in true fullscreen mode:

  attributes |= RENDERER_ATTRIBUTE_FORCE_PACING;

  Reference: app/streaming/video/ffmpeg-renderers/d3d11va.cpp:1474

  ---
  Statistics

  The pacer records how much time frames spend waiting before render:

  m_VideoStats->totalPacerTimeUs +=
      (beforeRender - (uint64_t)frame->pkt_dts);

  Reference: app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp:336

  It also tracks dropped frames:

  m_VideoStats->pacerDroppedFrames++;

  References:

  - app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp:239
  - app/streaming/video/ffmpeg-renderers/pacer/pacer.cpp:386

  ---
  Summary

  Moonlight’s frame pacing protocol is a small, adaptive frame queueing system between FFmpeg decode and renderer presentation.

  It works by:

  1. Receiving decoded frames from FFmpeg.
  2. Queueing them in a small pacing queue if V-sync pacing is available.
  3. Releasing one frame per V-sync event.
  4. Using 500 ms queue history to decide whether backlog is temporary or persistent.
  5. Dropping old frames when queues remain too deep.
  6. Letting renderers wait until their presentation pipeline is ready before latching the next frame.
  7. Keeping maximum buffering small to avoid latency and decoder surface starvation.

  The system is intended to reduce micro-stutter while preserving Moonlight’s low-latency streaming behavior.