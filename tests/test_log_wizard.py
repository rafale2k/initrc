import unittest
from unittest.mock import patch
import sys
import os
import io
import subprocess

# Add the root directory to sys.path to import from scripts
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from scripts.log_wizard import analyze_with_llm, analyze_logs

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

    @patch('sys.stdout', new_callable=io.StringIO)
    @patch('sys.stdin')
    def test_analyze_logs_isatty(self, mock_stdin, mock_stdout):
        mock_stdin.isatty.return_value = True
        analyze_logs()
        self.assertEqual(mock_stdout.getvalue().strip(), "Usage: docker logs <id> 2>&1 | lz")

    @patch('sys.stdout', new_callable=io.StringIO)
    @patch('sys.stdin')
    def test_analyze_logs_empty_input(self, mock_stdin, mock_stdout):
        mock_stdin.isatty.return_value = False
        mock_stdin.__iter__.return_value = iter([])
        analyze_logs()
        self.assertIn("✨ 異常ログは見つかりませんでした。", mock_stdout.getvalue())

    @patch('scripts.log_wizard.analyze_with_llm')
    @patch('sys.stdout', new_callable=io.StringIO)
    @patch('sys.stdin')
    def test_analyze_logs_with_errors(self, mock_stdin, mock_stdout, mock_analyze_with_llm):
        mock_stdin.isatty.return_value = False
        # Create some log lines with keywords and without
        log_lines = [
            "Normal log entry\n",
            "This is an error in the system\n",
            "Another failed attempt\n",
            "Just a regular info log\n",
            "This is an error in the system\n"  # duplicate to test counts
        ]
        mock_stdin.__iter__.return_value = iter(log_lines)

        # Mock the LLM analysis response
        mock_analyze_with_llm.return_value = "Mocked LLM Analysis"

        analyze_logs()

        output = mock_stdout.getvalue()

        # Verify it found errors and called the LLM
        self.assertIn("🚀 Gemini 3.8 Flash Analysis (Top 3 Errors)", output)
        self.assertIn("This is an error in the system", output)
        self.assertIn("Another failed attempt", output)
        self.assertIn("Mocked LLM Analysis", output)
        self.assertEqual(mock_analyze_with_llm.call_count, 2)

if __name__ == '__main__':
    unittest.main()
