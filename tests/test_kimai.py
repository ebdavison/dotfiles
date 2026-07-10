from __future__ import annotations

import io
import os
import unittest
from contextlib import redirect_stdout
from importlib.machinery import SourceFileLoader
from importlib.util import module_from_spec, spec_from_loader
from pathlib import Path
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
