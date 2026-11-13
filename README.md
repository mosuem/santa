# santa

## Annual Setup Workflow

1. Export `Blatt 1` of the master Google Sheet to `data/input.tsv`.
2. Capture product screenshots into `data/raw_screenshots/1.png` .. `100.png`:
   - **Flutter desktop GUI (auto-watches clipboard/screenshots + optional crop box):**
     ```bash
     cd tools/screenshot_app && flutter run -d linux
     ```
   - **Or CLI helper:** `dart run tools/capture_helper.dart --open`
3. Generate `data/total_hashed.json` and convert screenshots to `web/screenshots/<hash>.webp`:
   ```bash
   dart run tools/generate_hashes.dart
   ```
4. Upload `data/total_hashed.json` to Firebase Realtime Database (`toy-appeal-muc-default-rtdb`) and deploy web hosting (which bundles `web/screenshots/`):
   ```bash
   flutter build web && firebase deploy --only hosting
   ```
