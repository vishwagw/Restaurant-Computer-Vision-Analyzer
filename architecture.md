**Overview**:
- **Purpose**: Prototype pipeline for analyzing restaurant images to extract demographic attributes, food detection, emotion/satisfaction, queue detection, density heatmaps, and visit-duration tracking.
- **Scope**: Offline folder-based image analysis with optional "real" model support (DeepFace, YOLO) and lightweight fallbacks (deterministic stubs, OpenCV Haar cascades).

**High-level Data Flow**:
- Input: image files in a folder (ordered by name/mtime).
- Orchestration: `pipeline.analyze_folder` iterates images and for each image:
  - Run age/gender/ethnicity inference via `inference_stubs` or `inference_real` (switch via `--real`).
  - Run food/object detection via YOLO (`inference_real.predict_food_label`) or stub (`inference_stubs.predict_food_label`).
  - Optionally run emotion analysis via `EmotionAnalyzer` in `emotion.py` (controlled by `--emotion`).
  - Construct a record per image (timestamp, camera_id, image_path, age_est, gender, ethnicity, food_label, food_conf, optional emotion fields).
- Aggregation: `aggregator.records_to_csv` writes records; `aggregator.basic_time_series` computes rolling aggregations.
- Optional components (CLI flags):
  - Visit-duration tracking (`visit_tracker.VisitTracker`) — groups frames into visits and writes `visits.csv`.
  - Density/heatmap analysis (`density.DensityAnalyzer`) — accumulates point detections across frames and creates heatmap images and hotspot CSV.
  - Queue detection (`queue.QueueDetector` / `detect_queue_over_folder`) — uses person detector or face-proxy + `SimpleTracker` to detect queue events.

**Module Responsibilities**:
- `pipeline.py`:
  - Core orchestrator for folder analysis (`analyze_folder`, `list_image_files`, wrappers for density analyzer).
  - Loads inference implementations (real vs stubs) lazily and coordinates optional emotion analysis and alert generation.
- `inference_stubs.py`:
  - Deterministic, dependency-free stubs for age/gender/ethnicity and food labels for quick testing and reproducible outputs.
- `inference_real.py`:
  - Adapters for heavy models: DeepFace for face attributes, YOLO (ultralytics) for object/food detection. Handles device placement and best-effort fallbacks.
- `emotion.py`:
  - `EmotionAnalyzer`: prefer `fer` when installed, otherwise use OpenCV Haar-cascade fallback (face+smile heuristic). Maps emotions to a coarse `satisfaction` score.
- `aggregator.py`:
  - CSV writing helpers (`records_to_csv`, `visits_to_csv`) and aggregation utilities (`basic_time_series`) using `pandas`.
- `visit_tracker.py`:
  - `VisitTracker`: groups face crops into visits using DeepFace embeddings (when available) or aHash fallback; finalizes visits and exports records.
- `density.py`:
  - `DensityAnalyzer`: accumulates center points (from face detection) across frames, produces blurred heatmap and hotspot extraction + image annotations.
- `queue.py`:
  - `PersonDetector`, `SimpleTracker`, `QueueDetector`: person detection (YOLO fallback, face proxy), centroid-based tracking, and queue inference over frames.
- `cli.py` and `run_example.py`:
  - CLI user entrypoint wiring to `pipeline.analyze_folder` and optional features (visits, density, queue). `run_example.py` calls `cli()`.

**Key Control Flags & Behavior**:
- `--real`: use real heavy models (`inference_real`) if installed; otherwise falls back to stubs. Optional heavy packages: `ultralytics`, `deepface`, `torch`, `facenet-pytorch`, `retinaface`.
- `--emotion`: enable emotion analysis (uses `fer` when available; OpenCV fallback always present).
- `--visits-output` and `--visit-timeout`: enable visit-duration tracking and configure timeout.
- `--density-output`: create density heatmap and hotspot artifacts.
- `--queue-detect` and queue-related flags: run queue detection over folder.
- `--alerts-output` and `--alert-threshold`: record alerts when negative emotions exceed confidence threshold.

**Optional Dependencies & Fallbacks**:
- GPU/torch: code autodetects `torch.cuda.is_available()` and uses device where supported. Many real-models are optional; the code is designed to run without them using stubs/fallbacks.
- Emotion: prefers `fer` (more robust), falls back to Haar-based smile detector.
- Face detection: prefers RetinaFace -> MTCNN -> Haar cascade.
- Person detection: prefers YOLO person class; falls back to face-center proxy in `DensityAnalyzer`/`PersonDetector`.

**Storage & Outputs**:
- Primary CSV: `results.csv` (list of per-image records written by `aggregator.records_to_csv`). Fields include timestamps, camera_id, demographics, food label/confidence, and optional emotion fields.
- Visits CSV: `visits.csv` (visit_id, camera_id, start_ts, end_ts, duration_s, frames).
- Density outputs: `heatmap.png`, `hotspots.png`, `hotspots.csv` in an output directory.
- Queue results: CSV of per-frame queue metrics if requested.
- Alerts: optional CSV path for alert rows when negative emotions are detected.

**Integration Points & Extension Recommendations**:
- Replace stubs with model wrappers: implement `inference_real` functions or add new adapters that expose the same function signatures (`predict_food_label`, `predict_age_gender_ethnicity`). Keep the lazy-loading pattern to avoid forcing heavy deps.
- Improve person detection for density and queue analysis: replace face-center proxy with a dedicated person detector (fine-tuned YOLOv8 person model or pose/keypoint based detector).
- Make processing streaming-friendly: convert `analyze_folder` to a streaming consumer that accepts frames from a camera or message queue. Consider batching model inferences for throughput.
- Async / concurrency: model inference (YOLO / DeepFace) can be the bottleneck — add worker pools and queues for parallelized processing across frames.
- Persist to a DB: swap CSV outputs for a small database (SQLite or Postgres) for easier querying and retention management.
- Tests: add unit tests around aggregations (`aggregator.basic_time_series`), tracker behaviors (`visit_tracker`), and queue detection logic (`queue.SimpleTracker`).

**Privacy, Ethics & Legal Notes**:
- The repo includes face-based attributes (age/gender/ethnicity) and re-identification logic — these can be regulated as biometric processing in many jurisdictions. Carefully evaluate legal compliance (GDPR, CCPA, local laws) and obtain ethics/privacy review before deployment.
- The README already includes explicit warnings. Keep those visible and add automated gating (e.g., require an explicit config flag enabling biometric features).

**Developer Quickmap (files -> quick summary)**
- `pipeline.py`: orchestrator, main analysis loop
- `inference_stubs.py`: deterministic test stubs
- `inference_real.py`: adapters to DeepFace/YOLO (optional heavy deps)
- `emotion.py`: emotion/satisfaction analyzer (FER or Haar fallback)
- `aggregator.py`: CSV/aggregation helpers
- `visit_tracker.py`: visit grouping via embeddings / aHash
- `density.py`: heatmap and hotspot extraction
- `queue.py`: person detection + centroid tracking + queue detection
- `cli.py`, `run_example.py`: CLI front-end
- `requirements.txt`: minimal required packages; heavy deps commented as optional

**Simple ASCII Data Flow Diagram**:

Images Folder -> `pipeline.analyze_folder` -> [Inference (age/gender/ethnicity), Food Detection] -> attach Emotion (optional) -> append per-image record -> `aggregator.records_to_csv`
                                                                   |
                                                                   +-> Optional: `visit_tracker` (run separately over frames) -> `visits.csv`
                                                                   +-> Optional: `density.DensityAnalyzer` -> heatmap/hotspots
                                                                   +-> Optional: `queue.QueueDetector` -> queue CSV/alerts

**How to run (dev)**
- Create venv & install minimal deps:

```powershell
python -m venv .venv; .\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

- Run example (stub mode):

```powershell
python run_example.py --input sample_frames --output results.csv --camera-id CAM01
```

- Run with real models (install optional heavy deps first):

```powershell
pip install ultralytics deepface torch torchvision facenet-pytorch retinaface
python run_example.py --input sample_frames --output results.csv --camera-id CAM01 --real --emotion
```

**Open Questions & Next Steps (suggested)**
- Add a small sequence diagram or Mermaid diagram if you want richer visuals in `architecture.md`.
- Add unit tests for aggregation and tracker logic.
- Decide persistent storage (CSV vs DB) for production workflows.
- Add explicit config for enabling/disabling biometric features to ensure safety-by-default.

