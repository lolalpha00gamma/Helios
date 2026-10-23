import hashlib
import io
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from helios import model_asset


class ModelAssetTests(unittest.TestCase):
    def test_download_integrity_and_cleanup(self):
        valid = b"verified test model"
        with tempfile.TemporaryDirectory() as folder, patch.object(model_asset, "MODEL_SIZE", len(valid)), patch.object(model_asset, "MODEL_SHA256", hashlib.sha256(valid).hexdigest()):
            root = Path(folder)
            bundled, cache = root / "bundled", root / "cache"
            for invalid in [b"short", b"x" * len(valid), valid + b"x"]:
                with patch.object(model_asset.urllib.request, "urlopen", return_value=io.BytesIO(invalid)):
                    with self.assertRaises(RuntimeError):
                        model_asset.model_path(bundled=bundled, cache=cache)
                self.assertFalse(cache.exists())
                self.assertEqual(list(root.glob("*.part")), [])
            with patch.object(model_asset.urllib.request, "urlopen", return_value=io.BytesIO(valid)) as request:
                self.assertEqual(model_asset.model_path(bundled=bundled, cache=cache), cache)
                request.assert_called_once_with(model_asset.MODEL_URL, timeout=30)
            with patch.object(model_asset.urllib.request, "urlopen") as request:
                self.assertEqual(model_asset.model_path(bundled=bundled, cache=cache), cache)
                request.assert_not_called()
            self.assertEqual(cache.read_bytes(), valid)

    def test_failed_download_keeps_existing_cache(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            cache = root / "cache"
            cache.write_bytes(b"old")
            with patch.object(model_asset.urllib.request, "urlopen", side_effect=TimeoutError):
                with self.assertRaises(TimeoutError):
                    model_asset.model_path(bundled=root / "missing", cache=cache)
            self.assertEqual(cache.read_bytes(), b"old")
            self.assertEqual(list(root.glob("*.part")), [])


if __name__ == "__main__":
    unittest.main()
