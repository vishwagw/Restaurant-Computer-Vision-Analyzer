# Restaurant CV Analyzer

Quick instructions for running the web UI for the `restaurant_cv_analyzer` package.

Recommended (run as package)

Open a terminal at the project root (the folder that contains the `restaurant_cv_analyzer` package directory) and run:

```powershell
cd 'd:\Project Point View\restaurant_cv_analyzer'
python -m restaurant_cv_analyzer.webapp
```

This runs the app as a package so package-relative imports work reliably.

Alternative (run the module file directly)

If you prefer to run the module file directly, you can run `webapp.py` from the package folder. The project includes an import fallback so this will work in most environments:

```powershell
cd 'd:\Project Point View\restaurant_cv_analyzer\restaurant_cv_analyzer'
python webapp.py
```

Notes
- If your environment loads heavy ML dependencies (TensorFlow, DeepFace, etc.), expect startup warnings and longer import times.
- Prefer the `python -m ...` form for reproducible behavior and to avoid "attempted relative import with no known parent package" errors.
Restaurant CV Analyzer — Prototype

This prototype provides a minimal, runnable pipeline for analyzing customer images to produce aggregated demographic and food-detection outputs in CSV format.

Features:
- CLI to analyze a folder of images
- Deterministic "stub" inference for age, gender, ethnicity, and food label (no large model downloads)
- Aggregator producing a CSV with timestamped records
 - Real-time facial emotion/satisfaction analysis (optional). Uses `fer` when installed, otherwise falls back to a lightweight OpenCV smile detector.
 - Real-time facial emotion/satisfaction analysis (optional). Uses `fer` when installed, otherwise falls back to a lightweight OpenCV smile detector.
 - Automatic alerts: when a negative emotion is detected (e.g. `sad`, `angry`, `confused`, `fear`, `disgust`) the pipeline will print an alert and can write alert rows to a CSV via the CLI flag `--alerts-output`.
 - Automatic alerts: when a negative emotion is detected (e.g. `sad`, `angry`, `confused`, `fear`, `disgust`) the pipeline will print an alert and can write alert rows to a CSV via the CLI flag `--alerts-output`.
	 Use `--alert-threshold` to require a minimum emotion confidence (0..1) before an alert is emitted. Default is `0.5`.

Quick start

1. Create a Python environment (Windows PowerShell):

```powershell
python -m venv .venv; .\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

2. Run the example on `sample_frames`:

```powershell
python run_example.py --input sample_frames --output results.csv --camera-id CAM01
```

Notes
- This is a prototype with inference stubs. Replace `inference_stubs.py` with real model code when ready.
-- Ethnicity inference is included only as a placeholder; ensure legal and ethical review before using in production.

Real models (optional)

The prototype supports real-model inference using `DeepFace` (age/gender/ethnicity) and `YOLOv8` (object/food detection). These dependencies are heavy (TensorFlow / PyTorch) and are optional:

1. To install optional real-model dependencies (may take time and require the correct torch wheel for your system):

```powershell
# from the project root
# activate your venv first
pip install ultralytics deepface torch torchvision
```

2. Run with the `--real` flag to use real models (falls back to deterministic stubs if models aren't available):

```powershell
python "d:\\Project Point View\\restaurant_cv_analyzer\\run_example.py" --input "d:\\Project Point View\\restaurant_cv_analyzer\\sample_frames" --output "results.csv" --camera-id CAM01 --real
```

Notes on accuracy and privacy
- The YOLOv8 general COCO model is not trained specifically for food — accuracy will vary. For production, fine-tune a detector on your menu.
- DeepFace provides a quick way to prototype face-based attributes but evaluate thoroughly for fairness and bias before any deployment.

Face detectors (optional)

The tracker can use several face detectors (in order of preference):

- **RetinaFace** (`retinaface` package) — recommended for robust multi-face detection and better accuracy in varied poses and lighting. Install with `pip install retinaface`.
- **MTCNN** (`facenet-pytorch`) — used previously; good default if RetinaFace is not installed. Install with `pip install facenet-pytorch` and the correct `torch` wheel.
- **Haar cascade** (OpenCV) — fallback lightweight detector included by default, less robust.

To enable RetinaFace detection, install the optional dependency and run with `--real` (if you also want DeepFace embeddings):

```powershell
pip install retinaface
python "d:\\Project Point View\\restaurant_cv_analyzer\\run_example.py" --input "d:\\Project Point View\\restaurant_cv_analyzer\\sample_frames" --visits-output "visits.csv" --real
```

GPU auto-detection

The code now auto-detects a CUDA-capable GPU (via `torch.cuda.is_available()`) and will use the GPU when available for supported components:

- `MTCNN` (facenet-pytorch) will be created with the detected device.
- `YOLO` (ultralytics) model will be moved to the device where supported.

If you want to force CPU-only execution, set the environment variable `CUDA_VISIBLE_DEVICES` to an empty string before running:

```powershell
setx CUDA_VISIBLE_DEVICES ""
# then restart your shell/session
```

Visit-duration detection

This prototype includes a simple visit-duration tracker that groups image frames into visits and estimates how long a customer spent after sitting.

- Usage (frames must come from the same camera and be ordered by time):

```powershell
python "d:\\Project Point View\\restaurant_cv_analyzer\\run_example.py" --input "d:\\Project Point View\\restaurant_cv_analyzer\\sample_frames" --output "results.csv" --visits-output "visits.csv"
```

- By default the tracker uses a simple image average-hash (aHash) for matching across frames. If you install `deepface` and run with `--real`, the tracker will attempt to use DeepFace embeddings for better re-identification.
- You can control how long to wait before ending a visit with `--visit-timeout` (seconds). Default is 300 (5 minutes).

Output: `visits.csv` contains rows with `visit_id, camera_id, start_ts, end_ts, duration_s, frames`.

Privacy note: visit-duration tracking uses face-based re-identification logic when `deepface` is enabled. Do not enable or deploy face-based tracking without a privacy and legal review. The default aHash fallback is less accurate and still may constitute biometric processing in some jurisdictions.

Density / hotspot analysis

- The prototype now includes a lightweight density/heatmap analyzer that accumulates detected person (face) locations across frames and produces a heatmap and hotspot annotations. Use the `--density-output` CLI flag to write results to a directory.

- Example:

```powershell
python run_example.py --input sample_frames --density-output density_out
```


Occupancy analysis (new)

- The prototype now includes a simple ROI-based occupancy analyzer that can detect whether tables are occupied, become vacant, and escalate to `needs_cleaning` after a configurable delay. The implementation lives in `restaurant_cv_analyzer/occupancy.py` and is integrated into the pipeline when you pass `table_rois`.
- Usage (programmatic): call `analyze_folder(..., table_rois=table_rois)` where `table_rois` is a mapping of `table_id -> (x1, y1, x2, y2)` in pixel coordinates. Each returned record for a frame will include a `tables` snapshot showing per-table `occupied`, `last_seen_ts`, `last_vacant_ts`, and `status`.

Example (programmatic):

```python
from restaurant_cv_analyzer import pipeline

table_rois = {
	'T1': (10, 10, 60, 60),
	'T2': (80, 10, 130, 60)
}

## Web UI

A lightweight Flask-based web UI is provided in `restaurant_cv_analyzer/webapp.py`.
To run the UI (after installing dependencies) execute (PowerShell):

```powershell
python -m restaurant_cv_analyzer.webapp
```

The UI lets you point to an input folder (for example `sample_frames`) and run the analyzer from a browser. The server listens by default on port `5000`.

## Desktop App (pywebview)

You can run the project as a native desktop application using `pywebview`.

1. Install dependencies (including GUI runtime) into your venv:

```powershell
pip install -r requirements.txt
```

2. Launch the desktop app:

```powershell
python -m restaurant_cv_analyzer.desktop
```

The launcher starts the local web server on a free port and opens a native
window using `pywebview`. If `pywebview` cannot be used on your platform the
launcher will fall back to opening the UI in your system browser.

## Packaging a single-file Windows executable (PyInstaller)

You can produce a one-file Windows executable that bundles the Flask app,
templates and static assets using PyInstaller. The project includes a spec
file and a small build script to streamline the process.

1. Activate your virtual environment and install build deps:

```powershell
python -m venv .venv; .\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
pip install pyinstaller
```

2. From the project root run the build script (PowerShell):

```powershell
.\tools\build_windows.ps1
```

3. When the build completes the one-file executable will be in `dist\restaurant_cv_analyzer_desktop.exe`.

Notes:
- The included spec (`restaurant_cv_analyzer.spec`) uses PyInstaller utilities to collect package data and submodules. If your environment requires extra hidden imports (e.g., when using optional heavy dependencies like `torch`), you can add them to the `hiddenimports` list in the spec or pass `--hidden-import` flags to PyInstaller.
- On Windows, `pywebview` may need an additional GUI backend (e.g., `pywebview[qt]`). If the generated executable fails to start due to a missing backend, install the appropriate extras and rebuild.

## Creating a Windows Installer (NSIS)

After you have produced the one-file executable with PyInstaller (see previous section), you can wrap it in a native Windows installer using NSIS.

1. Install NSIS on Windows: https://nsis.sourceforge.io/Download

2. From the project root run the installer build script (PowerShell):

```powershell
.\tools\build_installer.ps1 -ExePath .\dist\restaurant_cv_analyzer_desktop.exe -Version 0.1.0
```

The script will invoke `makensis` to compile `tools\installer.nsi` into an installer under the `dist` folder. The NSIS script creates a Start Menu shortcut and an uninstaller.

If you need to customize the installer (icon, additional files, license, registry entries), edit `tools\installer.nsi` accordingly.

records = pipeline.analyze_folder('sample_frames', camera_id='CAM01', table_rois=table_rois)
for rec in records[:5]:
	print(rec.get('tables'))
```

- CLI: the current CLI does not include a flag to pass ROIs directly. You can either run the pipeline programmatically (example above) or extend the CLI to accept a `--table-rois` JSON file that is parsed and forwarded to `analyze_folder`. If you want, I can add the CLI flag in a follow-up change.

Dependencies and notes

- The occupancy analyzer uses OpenCV Haar cascade face detection by default (provided by `opencv-python`). This is lightweight but less robust — for production replace or augment with RetinaFace or MTCNN (see "Face detectors" above).
- The analyzer supports injecting detection boxes programmatically (via `OccupancyAnalyzer.process_frame(..., detected_boxes=[(x1,y1,x2,y2), ...])`) so you can feed detections from a stronger detector or your existing tracker instead of relying on the Haar cascade.
- Configurable timings: `vacancy_hold_seconds` (how long without detection to consider the table vacated) and `cleaning_hold_seconds` (how long after vacancy before marking `needs_cleaning`).
