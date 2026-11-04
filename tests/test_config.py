"""Static checks for send-only configuration contract (stdlib unittest)."""
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
CONFIG = (ROOT / "scripts/configure.py").read_text()

class SecurityContract(unittest.TestCase):
    def test_no_local_delivery(self):
        self.assertIn('"local_transport": "error:Local delivery disabled"', CONFIG)
        self.assertIn('"virtual_transport": "error:Virtual delivery disabled"', CONFIG)
        self.assertIn('"mydestination": ""', CONFIG)
        self.assertIn('"relay_domains": ""', CONFIG)

    def test_no_unrestricted_master_overrides(self):
        self.assertIn('master.cf overrides are deliberately unsupported', CONFIG)
        self.assertNotIn("local unix", CONFIG)
        self.assertNotIn("virtual unix", CONFIG)

    def test_restricted_clients(self):
        self.assertIn('"smtpd_relay_restrictions": "permit_mynetworks,reject"', CONFIG)
        self.assertIn('"smtpd_client_restrictions": "permit_mynetworks,reject"', CONFIG)

    def test_no_env_dump(self):
        self.assertNotIn("\nenv\n", (ROOT / "docker-entrypoint.sh").read_text())

if __name__ == "__main__":
    unittest.main()
