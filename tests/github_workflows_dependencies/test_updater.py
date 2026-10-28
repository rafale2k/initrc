import unittest
from unittest.mock import patch, MagicMock
import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../.github/workflows/dependencies')))

from updater import GitHub

class TestGitHub(unittest.TestCase):
    @patch('updater.requests.get')
    def test_check_newer_tag_non_200_status(self, mock_get):
        # Setup mock response
        mock_response = MagicMock()
        mock_response.status_code = 404
        mock_response.json.return_value = {"message": "Not Found"}
        mock_get.return_value = mock_response

        # According to the codebase, check_newer_tag and check_updates handle non-200 by raising Exception (except in the issue description which is slightly different, but the code shows it raises an Exception)
        with self.assertRaises(Exception) as context:
            GitHub.check_newer_tag('test/repo', 'v1.0.0')
        self.assertIn('GitHub API request failed with status code 404', str(context.exception))

    @patch('updater.requests.get')
    def test_check_updates_non_200_status(self, mock_get):
        # Setup mock response
        mock_response = MagicMock()
        mock_response.status_code = 500
        mock_response.json.return_value = {"message": "Internal Server Error"}
        mock_get.return_value = mock_response

        with self.assertRaises(Exception) as context:
            GitHub.check_updates('test/repo', 'main', 'abcdef')
        self.assertIn('GitHub API request failed with status code 500', str(context.exception))

if __name__ == '__main__':
    unittest.main()
