from __future__ import annotations

import io
import json
import os
import unittest
from contextlib import redirect_stdout
from contextlib import redirect_stderr
from importlib.machinery import SourceFileLoader
from importlib.util import module_from_spec, spec_from_loader
from pathlib import Path
from tempfile import TemporaryDirectory
from urllib.error import URLError
from urllib.request import Request
from unittest.mock import patch


def load_kimai():
    path = Path(__file__).resolve().parents[1] / "bin" / "kimai"
    loader = SourceFileLoader("kimai", str(path))
    spec = spec_from_loader("kimai", loader)
    module = module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class TestKimaiCLI(unittest.TestCase):
    def test_config_file_provides_defaults(self):
        with TemporaryDirectory() as tmpdir:
            config_dir = Path(tmpdir) / ".config" / "kimai"
            config_dir.mkdir(parents=True)
            (config_dir / "config.toml").write_text(
                'url = "https://file.example"\n'
                'token = "file-token"\n',
                encoding="utf-8",
            )
            kimai = load_kimai()
            with patch.object(kimai.Path, "home", return_value=Path(tmpdir)), patch.dict(os.environ, {}, clear=True):
                args = kimai.parse_args(["view"])
                settings = kimai.resolve_settings(args)
        self.assertEqual(settings["base_url"], "https://file.example")
        self.assertEqual(settings["token"], "file-token")

    def test_resolve_settings_prefers_flags_over_env(self):
        kimai = load_kimai()
        with patch.dict(
            os.environ,
            {"KIMAI_URL": "https://env.example", "KIMAI_TOKEN": "env-token"},
            clear=False,
        ):
            args = kimai.parse_args(["--url", "https://flag.example", "--token", "flag-token", "view"])
            settings = kimai.resolve_settings(args)
        self.assertEqual(settings["base_url"], "https://flag.example")
        self.assertEqual(settings["token"], "flag-token")

    def test_help_includes_start_stop_and_view(self):
        kimai = load_kimai()
        stdout = io.StringIO()
        with self.assertRaises(SystemExit) as exc, redirect_stdout(stdout):
            kimai.main(["--help"])
        self.assertEqual(exc.exception.code, 0)
        help_text = stdout.getvalue()
        self.assertIn("start", help_text)
        self.assertIn("stop", help_text)
        self.assertIn("view", help_text)


class DummyResponse:
    def __init__(self, payload: dict):
        self.payload = json.dumps(payload).encode("utf-8")

    def read(self):
        return self.payload

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False


class TestKimaiAPI(unittest.TestCase):
    def test_start_posts_expected_payload(self):
        kimai = load_kimai()
        captured = {}

        def fake_urlopen(request: Request):
            captured["url"] = request.full_url
            captured["method"] = request.method
            captured["body"] = request.data.decode("utf-8")
            return DummyResponse({"id": 42, "description": "Standup"})

        with patch.dict("os.environ", {"KIMAI_URL": "https://kimai.example", "KIMAI_TOKEN": "secret"}), patch(
            "urllib.request.urlopen",
            side_effect=fake_urlopen,
        ):
            stdout = io.StringIO()
            with redirect_stdout(stdout):
                exit_code = kimai.main(["start", "--project", "7", "--activity", "3", "--description", "Standup"])
        self.assertEqual(exit_code, 0)
        self.assertEqual(captured["url"], "https://kimai.example/api/timesheets")
        self.assertEqual(captured["method"], "POST")
        self.assertIn("project=7", captured["body"])
        self.assertIn("activity=3", captured["body"])
        self.assertIn("description=Standup", captured["body"])

    def test_view_prints_a_compact_row(self):
        kimai = load_kimai()

        def fake_urlopen(request: Request):
            return DummyResponse(
                {
                    "data": [
                        {"id": 42, "begin": "2026-07-10T08:00:00-05:00", "duration": 3600, "description": "Standup"}
                    ]
                }
            )

        with patch.dict("os.environ", {"KIMAI_URL": "https://kimai.example", "KIMAI_TOKEN": "secret"}), patch(
            "urllib.request.urlopen",
            side_effect=fake_urlopen,
        ):
            stdout = io.StringIO()
            with redirect_stdout(stdout):
                exit_code = kimai.main(["view", "--limit", "1"])
        self.assertEqual(exit_code, 0)
        self.assertIn("42", stdout.getvalue())
        self.assertIn("Standup", stdout.getvalue())

    def test_view_prints_top_level_list_response(self):
        kimai = load_kimai()

        def fake_urlopen(request: Request):
            return DummyResponse(
                [
                    {"id": 42, "begin": "2026-07-10T08:00:00-05:00", "duration": 3600, "description": "Standup"}
                ]
            )

        with patch.dict(os.environ, {"KIMAI_URL": "https://kimai.example", "KIMAI_TOKEN": "secret"}), patch(
            "urllib.request.urlopen",
            side_effect=fake_urlopen,
        ):
            stdout = io.StringIO()
            with redirect_stdout(stdout):
                exit_code = kimai.main(["view", "--limit", "1"])
        self.assertEqual(exit_code, 0)
        self.assertIn("42", stdout.getvalue())
        self.assertIn("Standup", stdout.getvalue())
        self.assertIn("01:00:00", stdout.getvalue())

    def test_view_by_id_prints_detailed_entry(self):
        kimai = load_kimai()

        def fake_urlopen(request: Request):
            self.assertEqual(request.full_url, "https://kimai.example/api/timesheets/1642")
            return DummyResponse(
                {
                    "id": 1642,
                    "begin": "2026-07-10T10:13:00-0500",
                    "end": "2026-07-10T11:02:00-0500",
                    "duration": 2940,
                    "description": "Configure postgresql on fincon server",
                    "project": {
                        "id": 2,
                        "name": "Server setup",
                        "customer": {"id": 8, "name": "Fincon"},
                    },
                    "activity": {"id": 9, "name": "Configuration"},
                }
            )

        with patch.dict(os.environ, {"KIMAI_URL": "https://kimai.example", "KIMAI_TOKEN": "secret"}), patch(
            "urllib.request.urlopen",
            side_effect=fake_urlopen,
        ):
            stdout = io.StringIO()
            with redirect_stdout(stdout):
                exit_code = kimai.main(["view", "1642"])
        self.assertEqual(exit_code, 0)
        output = stdout.getvalue()
        self.assertIn("ID: 1642", output)
        self.assertIn("Company: Fincon", output)
        self.assertIn("Project: Server setup [2]", output)
        self.assertIn("Activity: Configuration [9]", output)
        self.assertIn("Duration: 00:49:00", output)

    def test_main_rejects_missing_config(self):
        with TemporaryDirectory() as tmpdir:
            kimai = load_kimai()
            stdout = io.StringIO()
            stderr = io.StringIO()
            with patch.object(kimai.Path, "home", return_value=Path(tmpdir)), patch.dict(
                os.environ, {}, clear=True
            ), redirect_stdout(stdout), redirect_stderr(stderr):
                exit_code = kimai.main(["view"])
            self.assertEqual(exit_code, 1)
            self.assertEqual(stdout.getvalue(), "")
            self.assertIn("missing KIMAI_URL or --url", stderr.getvalue())

    def test_main_reports_network_errors(self):
        kimai = load_kimai()

        def fake_urlopen(request: Request):
            raise URLError("boom")

        stdout = io.StringIO()
        stderr = io.StringIO()
        with patch.dict(os.environ, {"KIMAI_URL": "https://kimai.example", "KIMAI_TOKEN": "secret"}), patch(
            "urllib.request.urlopen",
            side_effect=fake_urlopen,
        ), redirect_stdout(stdout), redirect_stderr(stderr):
            exit_code = kimai.main(["view"])
        self.assertEqual(exit_code, 1)
        self.assertEqual(stdout.getvalue(), "")
        self.assertIn("network error", stderr.getvalue())
