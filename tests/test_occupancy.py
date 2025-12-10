import tempfile
import os
import cv2
import numpy as np
from restaurant_cv_analyzer.occupancy import OccupancyAnalyzer


def _write_img(path, img):
    cv2.imwrite(path, img)


def test_occupancy_transitions():
    # small synthetic image: 150x100
    h, w = 100, 150
    # define two table ROIs
    table_rois = {
        'T1': (10, 10, 60, 60),
        'T2': (80, 10, 130, 60)
    }
    analyzer = OccupancyAnalyzer(table_rois, vacancy_hold_seconds=1, cleaning_hold_seconds=2)

    with tempfile.TemporaryDirectory() as td:
        # create image with a "face" drawn inside T1 (a dark circle)
        img1 = np.full((h, w, 3), 255, dtype=np.uint8)
        cv2.circle(img1, (30, 30), 8, (0, 0, 0), -1)
        p1 = os.path.join(td, 'frame1.jpg')
        _write_img(p1, img1)

        # inject a synthetic detected box that falls inside T1
        analyzer.process_frame(p1, ts=1000, camera_id='CAM_TEST', detected_boxes=[(22, 22, 38, 38)])
        evs = analyzer.get_and_clear_events()
        # Should have at least one occupied event for T1
        assert any(e['event'] == 'occupied' and e['table_id'] == 'T1' for e in evs)

        # create an image with no faces -> should cause vacated after vacancy_hold_seconds
        img2 = np.full((h, w, 3), 255, dtype=np.uint8)
        p2 = os.path.join(td, 'frame2.jpg')
        _write_img(p2, img2)

        analyzer.process_frame(p2, ts=1002, camera_id='CAM_TEST', detected_boxes=[])
        evs2 = analyzer.get_and_clear_events()
        assert any(e['event'] == 'vacated' and e['table_id'] == 'T1' for e in evs2)

        # advancing time to trigger needs_cleaning
        analyzer.process_frame(p2, ts=1005, camera_id='CAM_TEST', detected_boxes=[])
        evs3 = analyzer.get_and_clear_events()
        assert any(e['event'] == 'needs_cleaning' and e['table_id'] == 'T1' for e in evs3)
