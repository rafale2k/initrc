import sys
import os
import subprocess
import pytest
from unittest.mock import patch, MagicMock
from io import StringIO

# Add scripts directory to sys.path so we can import log_wizard
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'scripts')))

from log_wizard import analyze_with_llm, analyze_logs

def test_analyze_with_llm_success():
    with patch('subprocess.run') as mock_run:
        mock_process = MagicMock()
        mock_process.stdout = "Successful analysis output\n"
        mock_run.return_value = mock_process

        result = analyze_with_llm("error log")

        assert result == "Successful analysis output"
        mock_run.assert_called_once()
        args, kwargs = mock_run.call_args
        assert kwargs.get('capture_output') is True

def test_analyze_with_llm_non_gemini():
    with patch('os.environ.get', return_value="gpt-4o"):
        with patch('subprocess.run') as mock_run:
            mock_process = MagicMock()
            mock_process.stdout = "gpt-4o output"
            mock_run.return_value = mock_process

            analyze_with_llm("test log")

            args, _ = mock_run.call_args
            cmd = args[0]
            assert 'gpt-4o' in cmd
            assert '-o' not in cmd
            assert 'thinking_level' not in cmd

def test_analyze_with_llm_gemini():
    with patch('os.environ.get', return_value="gemini-3.8-flash"):
        with patch('subprocess.run') as mock_run:
            mock_process = MagicMock()
            mock_process.stdout = "gemini output"
            mock_run.return_value = mock_process

            analyze_with_llm("test log")

            args, _ = mock_run.call_args
            cmd = args[0]
            assert 'gemini-3.8-flash' in cmd
            assert '-o' in cmd
            assert 'thinking_level' in cmd
            assert 'low' in cmd

def test_analyze_with_llm_error():
    with patch('subprocess.run', side_effect=Exception("Test Exception Raised")):
        result = analyze_with_llm("error log")
        assert result.startswith("LLM Error:")
        assert "Test Exception R" in result

def test_analyze_logs_isatty(capsys):
    with patch('sys.stdin') as mock_stdin:
        mock_stdin.isatty.return_value = True

        analyze_logs()

        captured = capsys.readouterr()
        assert "Usage: docker logs <id> 2>&1 | lz" in captured.out

def test_analyze_logs_no_errors(capsys):
    with patch('sys.stdin', StringIO("info: application started\ninfo: everything ok\n")):
        analyze_logs()

        captured = capsys.readouterr()
        assert "異常ログは見つかりませんでした" in captured.out

def test_analyze_logs_with_errors(capsys):
    logs = (
        "error: connection failed\n"
        "error: connection failed\n"
        "warning: high memory usage\n"
        "critical: db down\n"
        "404 not found\n"
    )
    with patch('sys.stdin', StringIO(logs)):
        with patch('log_wizard.analyze_with_llm', return_value="Mocked analysis") as mock_analyze:
            analyze_logs()

            captured = capsys.readouterr()
            assert "Gemini 3.8 Flash Analysis (Top 3 Errors)" in captured.out
            assert "Rank 1" in captured.out
            assert "error: connection failed" in captured.out
            assert "💡 解析結果: Mocked analysis" in captured.out

            # Should be called up to 3 times (for top 3)
            assert mock_analyze.call_count == 3
import unittest
from unittest.mock import patch
import sys
import os
import subprocess

# Add the root directory to sys.path to import from scripts
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from scripts.log_wizard import analyze_with_llm

class TestLogWizard(unittest.TestCase):
    @patch('scripts.log_wizard.subprocess.run')
    def test_analyze_with_llm_error_path_generic_exception(self, mock_run):
        # Setup the mock to raise a generic exception
        error_msg = "Simulated error from subprocess"
        mock_run.side_effect = Exception(error_msg)

        # Call the function
        result = analyze_with_llm("test log")

        # Verify the result (should be truncated to 30 chars)
        expected_error_str = error_msg[:30]
        self.assertEqual(result, f"LLM Error: {expected_error_str}")

    @patch('scripts.log_wizard.subprocess.run')
    def test_analyze_with_llm_error_path_called_process_error(self, mock_run):
        # Setup the mock to raise a CalledProcessError
        error = subprocess.CalledProcessError(
            returncode=1,
            cmd=['llm', 'prompt'],
            output="Error output",
            stderr="Standard error"
        )
        mock_run.side_effect = error

        # Call the function
        result = analyze_with_llm("test log")

        # Verify the result
        expected_error_str = str(error)[:30]
        self.assertEqual(result, f"LLM Error: {expected_error_str}")

    @patch('scripts.log_wizard.subprocess.run')
    def test_analyze_with_llm_success_path(self, mock_run):
        # Setup the mock to return a completed process with stdout
        class MockCompletedProcess:
            stdout = "Analysis result\n"

        mock_run.return_value = MockCompletedProcess()

        # Call the function
        result = analyze_with_llm("test log")

        # Verify the result
        self.assertEqual(result, "Analysis result")

if __name__ == '__main__':
    unittest.main()
