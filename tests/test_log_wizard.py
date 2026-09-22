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
