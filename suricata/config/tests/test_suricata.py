#!/usr/bin/env python3
"""
Suricata Test Script for Mini-SOC Platform
Tests Suricata installation, configuration, and detection capabilities
"""

import subprocess
import sys
import os
import time
import json
import socket
import threading
from pathlib import Path

class SuricataTester:
    def __init__(self):
        self.results = {
            "installation": False,
            "configuration": False,
            "service": False,
            "detection": False,
            "rules": False
        }
        
    def print_status(self, message, status):
        """Print status message with colored output"""
        if status:
            print(f"\033[92m[✓] {message}\033[0m")
        else:
            print(f"\033[91m[✗] {message}\033[0m")
    
    def test_installation(self):
        """Test if Suricata is installed"""
        try:
            result = subprocess.run(
                ["suricata", "--build-info"],
                capture_output=True,
                text=True
            )
            if result.returncode == 0:
                self.results["installation"] = True
                self.print_status("Suricata is installed", True)
                print(f"  Version: {result.stdout.split()[1]}")
                return True
        except FileNotFoundError:
            self.print_status("Suricata is not installed", False)
        return False
    
    def test_configuration(self):
        """Test Suricata configuration"""
        config_path = "/etc/suricata/suricata.yaml"
        if not os.path.exists(config_path):
            config_path = "./config/suricata.yaml"
            
        if os.path.exists(config_path):
            try:
                result = subprocess.run(
                    ["suricata", "-T", "-c", config_path],
                    capture_output=True,
                    text=True,
                    timeout=30
                )
                if "Configuration provided was successfully loaded" in result.stdout:
                    self.results["configuration"] = True
                    self.print_status("Configuration test passed", True)
                    return True
                else:
                    self.print_status("Configuration test failed", False)
                    print(f"  Error: {result.stderr}")
            except subprocess.TimeoutExpired:
                self.print_status("Configuration test timed out", False)
        else:
            self.print_status(f"Configuration file not found at {config_path}", False)
        return False
    
    def test_service(self):
        """Test if Suricata service is running"""
        try:
            # Try systemctl first
            result = subprocess.run(
                ["systemctl", "is-active", "suricata"],
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0 and "active" in result.stdout:
                self.results["service"] = True
                self.print_status("Suricata service is running", True)
                return True
            
            # Check if Suricata process is running
            result = subprocess.run(
                ["pgrep", "suricata"],
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                self.results["service"] = True
                self.print_status("Suricata process is running", True)
                return True
                
        except Exception as e:
            pass
            
        self.print_status("Suricata service is not running", False)
        return False
    
    def test_rules(self):
        """Test if rules are loaded"""
        rules_path = "/etc/suricata/rules"
        if not os.path.exists(rules_path):
            rules_path = "./config/rules"
            
        # Check for rule files
        rule_files = list(Path(rules_path).glob("*.rules"))
        if rule_files:
            self.results["rules"] = True
            self.print_status(f"Found {len(rule_files)} rule files", True)
            for rf in rule_files[:3]:  # Show first 3
                print(f"  - {rf.name}")
            if len(rule_files) > 3:
                print(f"  ... and {len(rule_files) - 3} more")
            return True
        else:
            self.print_status("No rule files found", False)
            return False
    
    def generate_test_traffic(self):
        """Generate test traffic to trigger alerts"""
        print("\n[>] Generating test traffic...")
        
        # Create a simple ICMP ping (should trigger our test rule)
        try:
            # Send ICMP ping to localhost
            response = subprocess.run(
                ["ping", "-c", "3", "127.0.0.1"],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if response.returncode == 0:
                self.print_status("Test traffic generated", True)
                return True
                
        except Exception as e:
            self.print_status(f"Failed to generate test traffic: {e}", False)
            
        return False
    
    def check_alerts(self):
        """Check for generated alerts"""
        print("\n[>] Checking for alerts...")
        
        alert_files = [
            "/var/log/suricata/fast.log",
            "/var/log/suricata/eve.json",
            "./logs/suricata/fast.log",
            "./logs/suricata/eve.json"
        ]
        
        for alert_file in alert_files:
            if os.path.exists(alert_file):
                try:
                    # Check last few lines for alerts
                    with open(alert_file, 'r') as f:
                        lines = f.readlines()[-10:]  # Last 10 lines
                        
                    alerts_found = 0
                    for line in lines:
                        if "TEST RULE" in line or "sid:1000010" in line:
                            alerts_found += 1
                    
                    if alerts_found > 0:
                        self.results["detection"] = True
                        self.print_status(f"Found {alerts_found} test alert(s) in {alert_file}", True)
                        return True
                        
                except Exception as e:
                    continue
        
        self.print_status("No test alerts detected", False)
        return False
    
    def run_all_tests(self):
        """Run all tests"""
        print("=" * 60)
        print("Suricata Test Suite - Mini-SOC Platform")
        print("=" * 60)
        
        tests = [
            ("Installation Test", self.test_installation),
            ("Configuration Test", self.test_configuration),
            ("Service Test", self.test_service),
            ("Rules Test", self.test_rules)
        ]
        
        for test_name, test_func in tests:
            print(f"\n[+] Running {test_name}...")
            test_func()
            time.sleep(1)
        
        # Only run traffic test if service is running
        if self.results["service"]:
            print(f"\n[+] Running Detection Test...")
            self.generate_test_traffic()
            time.sleep(2)  # Wait for logs
            self.check_alerts()
        
        # Print summary
        print("\n" + "=" * 60)
        print("TEST SUMMARY")
        print("=" * 60)
        
        passed = sum(self.results.values())
        total = len(self.results)
        
        for test, result in self.results.items():
            status = "PASS" if result else "FAIL"
            color = "\033[92m" if result else "\033[91m"
            print(f"{color}{test:20} {status}\033[0m")
        
        print(f"\nTotal: {passed}/{total} tests passed")
        
        if passed == total:
            print("\033[92m[✓] All tests passed successfully!\033[0m")
            return 0
        else:
            print(f"\033[91m[!] {total - passed} test(s) failed\033[0m")
            return 1

def main():
    """Main function"""
    tester = SuricataTester()
    return tester.run_all_tests()

if __name__ == "__main__":
    sys.exit(main())