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
                'url = "https://file.example"\n' 'token = "file-token"\n',
                encoding="utf-8",
            )
            kimai = load_kimai()
            with patch.object(
                kimai.Path, "home", return_value=Path(tmpdir)
            ), patch.dict(os.environ, {}, clear=True):
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
            args = kimai.parse_args(
                [
                    "--url",
                    "https://flag.example",
                    "--token",
                    "flag-token",
                    "view",
                ]
            )
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

    def test_view_help_includes_sort_controls(self):
        kimai = load_kimai()
        stdout = io.StringIO()
        with self.assertRaises(SystemExit) as exc, redirect_stdout(stdout):
            kimai.main(["view", "--help"])
        self.assertEqual(exc.exception.code, 0)
        help_text = stdout.getvalue()
        self.assertIn("--sort", help_text)
        self.assertIn("--reverse", help_text)

    def test_view_help_includes_filter_controls(self):
        kimai = load_kimai()
        stdout = io.StringIO()
        with self.assertRaises(SystemExit) as exc, redirect_stdout(stdout):
            kimai.main(["view", "--help"])
        self.assertEqual(exc.exception.code, 0)
        help_text = stdout.getvalue()
        self.assertIn("--from", help_text)
        self.assertIn("--to", help_text)
        self.assertIn("--project", help_text)
        self.assertIn("--activity", help_text)
        self.assertIn("--company", help_text)

    def test_view_help_includes_debug_control(self):
        kimai = load_kimai()
        stdout = io.StringIO()
        with self.assertRaises(SystemExit) as exc, redirect_stdout(stdout):
            kimai.main(["--help"])
        self.assertEqual(exc.exception.code, 0)
        help_text = stdout.getvalue()
        self.assertIn("--debug", help_text)


class DummyResponse:
    def __init__(self, payload: dict):
        self.payload = json.dumps(payload).encode("utf-8")

    def read(self):
        return self.payload

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False


def request_url_key(request: Request) -> str:
    if "/api/timesheets/recent" in request.full_url:
        return request.full_url.split("?", 1)[0]
    return request.full_url


class TestKimaiAPI(unittest.TestCase):
    def test_start_posts_expected_payload(self):
        kimai = load_kimai()
        captured = {}

        def fake_urlopen(request: Request):
            captured["url"] = request.full_url
            captured["method"] = request.method
            captured["body"] = request.data.decode("utf-8")
            return DummyResponse({"id": 42, "description": "Standup"})

        with patch.dict(
            "os.environ",
            {"KIMAI_URL": "https://kimai.example", "KIMAI_TOKEN": "secret"},
        ), patch(
            "urllib.request.urlopen",
            side_effect=fake_urlopen,
        ):
            stdout = io.StringIO()
            with redirect_stdout(stdout):
                exit_code = kimai.main(
                    [
                        "start",
                        "--project",
                        "7",
                        "--activity",
                        "3",
                        "--description",
                        "Standup",
                    ]
                )
        self.assertEqual(exit_code, 0)
        self.assertEqual(
            captured["url"], "https://kimai.example/api/timesheets"
        )
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
                        {
                            "id": 42,
                            "begin": "2026-07-10T08:00:00-05:00",
                            "duration": 3600,
                            "description": "Standup",
                        }
                    ]
                }
            )

        with patch.dict(
            "os.environ",
            {"KIMAI_URL": "https://kimai.example", "KIMAI_TOKEN": "secret"},
        ), patch(
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
                    {
                        "id": 42,
                        "begin": "2026-07-10T08:00:00-05:00",
                        "duration": 3600,
                        "description": "Standup",
                    }
                ]
            )

        with patch.dict(
            os.environ,
            {"KIMAI_URL": "https://kimai.example", "KIMAI_TOKEN": "secret"},
        ), patch(
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

    def test_view_sorts_recent_entries_by_begin_descending(self):
        kimai = load_kimai()

        def fake_urlopen(request: Request):
            return DummyResponse(
                {
                    "data": [
                        {
                            "id": 1,
                            "begin": "2026-07-10T08:00:00-05:00",
                            "duration": 3600,
                            "description": "older",
                        },
                        {
                            "id": 2,
                            "begin": "2026-07-10T09:00:00-05:00",
                            "duration": 1800,
                            "description": "newer",
                        },
                    ]
                }
            )

        with patch.dict(
            os.environ,
            {"KIMAI_URL": "https://kimai.example", "KIMAI_TOKEN": "secret"},
        ), patch(
            "urllib.request.urlopen",
            side_effect=fake_urlopen,
        ):
            stdout = io.StringIO()
            with redirect_stdout(stdout):
                exit_code = kimai.main(["view", "--limit", "2"])
        self.assertEqual(exit_code, 0)
        lines = stdout.getvalue().splitlines()
        self.assertEqual(lines[0].split("\t")[0], "2")
        self.assertEqual(lines[1].split("\t")[0], "1")

    def test_view_can_sort_by_id(self):
        kimai = load_kimai()

        def fake_urlopen(request: Request):
            return DummyResponse(
                {
                    "data": [
                        {
                            "id": 5,
                            "begin": "2026-07-10T08:00:00-05:00",
                            "duration": 3600,
                            "description": "first",
                        },
                        {
                            "id": 12,
                            "begin": "2026-07-09T08:00:00-05:00",
                            "duration": 1800,
                            "description": "second",
                        },
                    ]
                }
            )

        with patch.dict(
            os.environ,
            {"KIMAI_URL": "https://kimai.example", "KIMAI_TOKEN": "secret"},
        ), patch(
            "urllib.request.urlopen",
            side_effect=fake_urlopen,
        ):
            stdout = io.StringIO()
            with redirect_stdout(stdout):
                exit_code = kimai.main(
                    ["view", "--limit", "2", "--sort", "id"]
                )
        self.assertEqual(exit_code, 0)
        lines = stdout.getvalue().splitlines()
        self.assertEqual(lines[0].split("\t")[0], "12")
        self.assertEqual(lines[1].split("\t")[0], "5")

    def test_view_reverse_flips_selected_sort_order(self):
        kimai = load_kimai()

        def fake_urlopen(request: Request):
            return DummyResponse(
                {
                    "data": [
                        {
                            "id": 5,
                            "begin": "2026-07-10T08:00:00-05:00",
                            "duration": 3600,
                            "description": "first",
                        },
                        {
                            "id": 12,
                            "begin": "2026-07-09T08:00:00-05:00",
                            "duration": 1800,
                            "description": "second",
                        },
                    ]
                }
            )

        with patch.dict(
            os.environ,
            {"KIMAI_URL": "https://kimai.example", "KIMAI_TOKEN": "secret"},
        ), patch(
            "urllib.request.urlopen",
            side_effect=fake_urlopen,
        ):
            stdout = io.StringIO()
            with redirect_stdout(stdout):
                exit_code = kimai.main(
                    ["view", "--limit", "2", "--sort", "id", "--reverse"]
                )
        self.assertEqual(exit_code, 0)
        lines = stdout.getvalue().splitlines()
        self.assertEqual(lines[0].split("\t")[0], "5")
        self.assertEqual(lines[1].split("\t")[0], "12")

    def test_view_filters_by_date_project_activity_and_company(self):
        kimai = load_kimai()
        responses = {
            "https://kimai.example/api/timesheets?page=1&size=500": {
                "data": [
                    {
                        "id": 20,
                        "begin": "2026-07-10T15:00:00-0500",
                        "duration": 3600,
                        "description": "match",
                        "project": 2,
                        "activity": 12,
                    },
                    {
                        "id": 19,
                        "begin": "2026-07-09T09:00:00-0500",
                        "duration": 1800,
                        "description": "outside date",
                        "project": 2,
                        "activity": 12,
                    },
                    {
                        "id": 18,
                        "begin": "2026-07-10T12:00:00-0500",
                        "duration": 1800,
                        "description": "wrong project",
                        "project": 3,
                        "activity": 12,
                    },
                ]
            },
            "https://kimai.example/api/projects/2": {
                "id": 2,
                "name": "IT Support",
                "customer": 8,
            },
            "https://kimai.example/api/projects/3": {
                "id": 3,
                "name": "Other Work",
                "customer": 8,
            },
            "https://kimai.example/api/activities/12": {
                "id": 12,
                "name": "Consult",
            },
            "https://kimai.example/api/customers/8": {
                "id": 8,
                "name": "Fincon",
            },
        }

        def fake_urlopen(request: Request):
            key = request_url_key(request)
            self.assertIn(key, responses)
            return DummyResponse(responses[key])

        with patch.dict(
            os.environ,
            {"KIMAI_URL": "https://kimai.example", "KIMAI_TOKEN": "secret"},
        ), patch(
            "urllib.request.urlopen",
            side_effect=fake_urlopen,
        ):
            stdout = io.StringIO()
            with redirect_stdout(stdout):
                exit_code = kimai.main(
                    [
                        "view",
                        "--limit",
                        "3",
                        "--from",
                        "2026-07-10",
                        "--to",
                        "2026-07-10",
                        "--project",
                        "IT Support",
                        "--activity",
                        "12",
                        "--company",
                        "Fincon",
                    ]
                )
        self.assertEqual(exit_code, 0)
        output = stdout.getvalue().splitlines()
        self.assertEqual(len(output), 1)
        self.assertIn("20\t2026-07-10T15:00:00-0500", output[0])
        self.assertIn("match", output[0])

    def test_view_paginates_recent_entries_before_filtering(self):
        kimai = load_kimai()
        older_page = [
            {
                "id": index,
                "begin": f"2026-06-{(index % 28) + 1:02d}T08:00:00-0500",
                "duration": 1800,
                "description": f"older {index}",
            }
            for index in range(500, 0, -1)
        ]
        responses = {
            "https://kimai.example/api/timesheets?page=1&size=500": {
                "data": older_page
            },
            "https://kimai.example/api/timesheets?page=2&size=500": {
                "data": [
                    {
                        "id": 501,
                        "begin": "2026-07-10T15:00:00-0500",
                        "duration": 3600,
                        "description": "paged match",
                    }
                ]
            },
        }

        def fake_urlopen(request: Request):
            self.assertIn(request.full_url, responses)
            return DummyResponse(responses[request.full_url])

        with patch.dict(
            os.environ,
            {"KIMAI_URL": "https://kimai.example", "KIMAI_TOKEN": "secret"},
        ), patch(
            "urllib.request.urlopen",
            side_effect=fake_urlopen,
        ):
            stdout = io.StringIO()
            with redirect_stdout(stdout):
                exit_code = kimai.main(
                    ["view", "--from", "2026-07-01", "--limit", "5"]
                )
        self.assertEqual(exit_code, 0)
        output = stdout.getvalue().splitlines()
        self.assertEqual(len(output), 1)
        self.assertIn("501\t2026-07-10T15:00:00-0500", output[0])
        self.assertIn("paged match", output[0])

    def test_view_debug_reports_pages_and_filter_counts(self):
        kimai = load_kimai()
        responses = {
            "https://kimai.example/api/timesheets?page=1&size=500": {
                "data": [
                    {
                        "id": 1,
                        "begin": "2026-06-01T09:00:00-0500",
                        "duration": 3600,
                        "description": "keep",
                    },
                    {
                        "id": 2,
                        "begin": "2026-05-01T09:00:00-0500",
                        "duration": 3600,
                        "description": "drop",
                    },
                ]
            },
            "https://kimai.example/api/timesheets?page=2&size=500": {
                "data": []
            },
        }

        def fake_urlopen(request: Request):
            self.assertIn(request.full_url, responses)
            return DummyResponse(responses[request.full_url])

        with patch.dict(
            os.environ,
            {"KIMAI_URL": "https://kimai.example", "KIMAI_TOKEN": "secret"},
        ), patch(
            "urllib.request.urlopen",
            side_effect=fake_urlopen,
        ):
            stdout = io.StringIO()
            stderr = io.StringIO()
            with redirect_stdout(stdout), redirect_stderr(stderr):
                exit_code = kimai.main(
                    ["--debug", "view", "--from", "2026-06-01"]
                )
        self.assertEqual(exit_code, 0)
        self.assertEqual(stdout.getvalue().splitlines()[0].split("\t")[0], "1")
        debug_output = stderr.getvalue()
        self.assertIn("fetch page=1 size=500", debug_output)
        self.assertIn("fetched=2", debug_output)
        self.assertIn("matched=1", debug_output)

    def test_view_by_id_prints_detailed_entry(self):
        kimai = load_kimai()
        responses = {
            "https://kimai.example/api/timesheets/1642": {
                "id": 1642,
                "begin": "2026-07-10T10:13:00-0500",
                "end": "2026-07-10T11:02:00-0500",
                "duration": 2940,
                "description": "Configure postgresql on fincon server",
                "project": 2,
                "activity": 9,
            },
            "https://kimai.example/api/projects/2": {
                "id": 2,
                "name": "Server setup",
                "customer": {"id": 8, "name": "Fincon"},
            },
            "https://kimai.example/api/activities/9": {
                "id": 9,
                "name": "Configuration",
            },
        }

        def fake_urlopen(request: Request):
            self.assertIn(request.full_url, responses)
            return DummyResponse(responses[request.full_url])

        with patch.dict(
            os.environ,
            {"KIMAI_URL": "https://kimai.example", "KIMAI_TOKEN": "secret"},
        ), patch(
            "urllib.request.urlopen",
            side_effect=fake_urlopen,
        ):
            stdout = io.StringIO()
            with redirect_stdout(stdout):
                exit_code = kimai.main(["view", "1642"])
        self.assertEqual(exit_code, 0)
        output = stdout.getvalue()
        self.assertIn("ID: 1642", output)
        self.assertIn("Company: Fincon [8]", output)
        self.assertIn("Project: Server setup [2]", output)
        self.assertIn("Activity: Configuration [9]", output)
        self.assertIn("Duration: 00:49:00", output)

    def test_view_by_id_resolves_numeric_customer_reference(self):
        kimai = load_kimai()
        responses = {
            "https://kimai.example/api/timesheets/1643": {
                "id": 1643,
                "begin": "2026-07-10T15:19:00-0500",
                "end": "2026-07-10T16:29:00-0500",
                "duration": 4200,
                "description": "test entry",
                "project": 2,
                "activity": 12,
            },
            "https://kimai.example/api/projects/2": {
                "id": 2,
                "name": "IT Support",
                "customer": 8,
            },
            "https://kimai.example/api/activities/12": {
                "id": 12,
                "name": "Consult",
            },
            "https://kimai.example/api/customers/8": {
                "id": 8,
                "name": "Fincon",
            },
        }

        def fake_urlopen(request: Request):
            self.assertIn(request.full_url, responses)
            return DummyResponse(responses[request.full_url])

        with patch.dict(
            os.environ,
            {"KIMAI_URL": "https://kimai.example", "KIMAI_TOKEN": "secret"},
        ), patch(
            "urllib.request.urlopen",
            side_effect=fake_urlopen,
        ):
            stdout = io.StringIO()
            with redirect_stdout(stdout):
                exit_code = kimai.main(["view", "1643"])
        self.assertEqual(exit_code, 0)
        output = stdout.getvalue()
        self.assertIn("Company: Fincon [8]", output)
        self.assertIn("Project: IT Support [2]", output)
        self.assertIn("Activity: Consult [12]", output)

    def test_main_rejects_missing_config(self):
        with TemporaryDirectory() as tmpdir:
            kimai = load_kimai()
            stdout = io.StringIO()
            stderr = io.StringIO()
            with patch.object(
                kimai.Path, "home", return_value=Path(tmpdir)
            ), patch.dict(os.environ, {}, clear=True), redirect_stdout(
                stdout
            ), redirect_stderr(
                stderr
            ):
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
        with patch.dict(
            os.environ,
            {"KIMAI_URL": "https://kimai.example", "KIMAI_TOKEN": "secret"},
        ), patch(
            "urllib.request.urlopen",
            side_effect=fake_urlopen,
        ), redirect_stdout(
            stdout
        ), redirect_stderr(
            stderr
        ):
            exit_code = kimai.main(["view"])
        self.assertEqual(exit_code, 1)
        self.assertEqual(stdout.getvalue(), "")
        self.assertIn("network error", stderr.getvalue())
