#!/usr/bin/env python3

import subprocess
import os
import sys
import time
import json
import logging
import requests
from typing import Dict, Any, Optional
from datetime import datetime, timedelta
import argparse
import colorama
from colorama import init, Fore, Style
from pathlib import Path

# Configure logging to suppress urllib3 debug messages
logging.getLogger('urllib3').setLevel(logging.WARNING)
from requests.auth import HTTPBasicAuth
import argparse

init(autoreset=True)

CONFIG_DIR = Path.home() / '.gpgkeymanager'
CONFIG_FILE = CONFIG_DIR / 'gpgkeymanager.json'

class GPGKeyManager:
    def __init__(self, debug: bool = False):
        self.debug = debug
        if self.debug:
            logging.basicConfig(level=logging.DEBUG)
        else:
            logging.basicConfig(level=logging.INFO)
        self.logger = logging.getLogger(__name__)

    def check_gpg_installed(self) -> bool:
        """Check if GPG is installed on the system."""
        try:
            subprocess.run(['gpg', '--version'], check=True, capture_output=True)
            return True
        except subprocess.CalledProcessError:
            self.logger.error("GPG is not installed")
            return False

    def verify_github_key(self, key_id: str) -> Dict[str, Any]:
        """Verify if a GPG key is configured in GitHub."""
        try:
            # Get the public key in ASCII armor format
            result = subprocess.run(['gpg', '--armor', '--export', key_id],
                                  capture_output=True, text=True, check=True)
            public_key = result.stdout
            
            # Get the key fingerprint
            fingerprint_result = subprocess.run(['gpg', '--fingerprint', key_id],
                                              capture_output=True, text=True, check=True)
            fingerprint_lines = fingerprint_result.stdout.split('\n')
            fingerprint = ''
            for line in fingerprint_lines:
                if line.startswith('      Key fingerprint = '):
                    fingerprint = line.split('=')[1].strip()
                    break
            
            # Check if the key exists in GitHub
            # This is a placeholder - in a real implementation we would need to:
            # 1. Authenticate with GitHub API
            # 2. Check if the key exists in the user's GPG keys
            # For now, we'll return False since we can't verify without API access
            
            return {
                'public_key': public_key,
                'fingerprint': fingerprint,
                'github_configured': False
            }
        except subprocess.CalledProcessError:
            return {
                'public_key': '',
                'fingerprint': '',
                'github_configured': False
            }

    def connect_to_github(self, key_id: str) -> bool:
        """Connect GPG key with GitHub account.
        
        Args:
            key_id: The GPG key ID to connect with GitHub
            
        Returns:
            bool: True if connection was successful, False otherwise
            
        Raises:
            ValueError: If required permissions are missing
        """
        try:
            # Get the GPG key details
            key_details = self.get_gpg_key_details(key_id)
            if not key_details:
                print(Fore.RED + "❌ Error: Could not get GPG key details")
                return False

            # Get the public key
            result = subprocess.run(['gpg', '--armor', '--export', key_id],
                                  capture_output=True, text=True, check=True)
            public_key = result.stdout.strip()

            # Get the fingerprint
            fingerprint_result = subprocess.run(['gpg', '--fingerprint', key_id],
                                              capture_output=True, text=True, check=True)
            fingerprint_lines = fingerprint_result.stdout.split('\n')
            fingerprint = ''
            for line in fingerprint_lines:
                if line.startswith('      Key fingerprint = '):
                    fingerprint = line.split('=')[1].strip()
                    break

            # Ask for GitHub PAT with proper permissions
            print(Fore.CYAN + "\nEnter your GitHub Personal Access Token (PAT):")
            print(Fore.YELLOW + "Required permissions:")
            print(Fore.YELLOW + "- gpg_key:read (Required)")
            print(Fore.YELLOW + "- gpg_key:write (Optional for uploading new keys)")
            pat = input(Fore.CYAN + "PAT: ")

            # Validate the token
            headers = {
                'Authorization': f'token {pat}',
                'Accept': 'application/vnd.github+json'
            }

            # Check if token has read permissions
            try:
                response = requests.get('https://api.github.com/user/gpg_keys', headers=headers)
                if response.status_code == 401:
                    print(Fore.RED + "❌ Error: Invalid GitHub PAT")
                    return False
                elif response.status_code == 403:
                    print(Fore.RED + "❌ Error: PAT missing required permissions (gpg_key:read)")
                    return False
            except requests.RequestException as e:
                print(Fore.RED + f"❌ Error: Failed to validate GitHub token: {e}")
                return False

            # Check if key already exists
            existing_keys = response.json()
            key_exists = any(key.get('fingerprint', '').upper() == fingerprint.upper() 
                           for key in existing_keys)

            # If key exists, just verify
            if key_exists:
                print(Fore.GREEN + "✓ GPG key already exists in GitHub account")
                return True

            # Check if we have write permissions
            try:
                # Try to upload a key (this will fail if we don't have write permissions)
                data = {
                    'armored_public_key': public_key
                }
                response = requests.post('https://api.github.com/user/gpg_keys', 
                                      headers=headers,
                                      json=data)
                
                if response.status_code == 403:
                    print(Fore.RED + "❌ Error: PAT missing write permissions (gpg_key:write)")
                    print(Fore.YELLOW + "ℹ️ The key exists in your GitHub account but you don't have permission to modify it")
                    return False
                elif response.status_code != 201:
                    print(Fore.RED + f"❌ Error: Failed to upload GPG key: {response.text}")
                    return False

                print(Fore.GREEN + "✓ Successfully uploaded GPG key to GitHub")
                
                # Wait for GitHub to process the key
                print(Fore.YELLOW + "ℹ️ Waiting for GitHub to process the key...")
                time.sleep(5)  # Wait 5 seconds
                
                # Verify the key was added
                response = requests.get('https://api.github.com/user/gpg_keys', headers=headers)
                existing_keys = response.json()
                key_exists = any(key.get('fingerprint', '').upper() == fingerprint.upper() 
                               for key in existing_keys)
                
                if key_exists:
                    print(Fore.GREEN + "✓ Successfully verified GPG key on GitHub")
                    return True
                else:
                    print(Fore.RED + "❌ Error: GPG key was not found in GitHub account after upload")
                    return False

            except requests.RequestException as e:
                print(Fore.RED + f"❌ Error during GitHub key upload: {e}")
                return False

        except subprocess.CalledProcessError as e:
            print(Fore.RED + f"❌ Error getting GPG key information: {e}")
            return False
        except Exception as e:
            print(Fore.RED + f"❌ Unexpected error: {e}")
            return False

    def load_config(self) -> Dict[str, Any]:
        """Load configuration from JSON file."""
        try:
            # Ensure the config directory exists
            CONFIG_DIR.mkdir(parents=True, exist_ok=True)
            
            if not CONFIG_FILE.exists():
                return {}
                
            with open(CONFIG_FILE, 'r') as f:
                return json.load(f)
        except json.JSONDecodeError:
            return {}
        except Exception as e:
            self.logger.error(f"Failed to load config: {e}")
            return {}

    def save_config(self, config: Dict[str, Any]) -> None:
        """Save configuration to JSON file."""
        try:
            # Ensure the config directory exists
            CONFIG_DIR.mkdir(parents=True, exist_ok=True)
            
            with open(CONFIG_FILE, 'w') as f:
                json.dump(config, f, indent=2)
            
            self.logger.info(f"Configuration saved to {CONFIG_FILE}")
        except Exception as e:
            self.logger.error(f"Failed to save config: {e}")
            raise RuntimeError(f"Failed to save configuration: {str(e)}")

    def clear_config(self) -> None:
        """Clear all configuration including Git GPG settings."""
        try:
            # Clear Git GPG configuration
            subprocess.run(['git', 'config', '--global', '--unset', 'user.signingkey'],
                         capture_output=True, text=True)
            subprocess.run(['git', 'config', '--global', '--unset', 'commit.gpgsign'],
                         capture_output=True, text=True)
            subprocess.run(['git', 'config', '--global', '--unset', 'tag.gpgsign'],
                         capture_output=True, text=True)
            
            # Clear our configuration directory and file
            if CONFIG_DIR.exists():
                if CONFIG_FILE.exists():
                    CONFIG_FILE.unlink()
                # Remove the directory if it's empty
                try:
                    CONFIG_DIR.rmdir()
                    self.logger.info("Configuration directory cleared successfully")
                except OSError:
                    self.logger.info("Configuration directory still contains files")
            else:
                self.logger.info("No configuration directory found")
                
            # Update status to reflect unconfigured state
            self.update_key_config('', '', '', '', False, False)
            
        except Exception as e:
            self.logger.error(f"Error clearing configuration: {e}")
            raise RuntimeError(f"Failed to clear configuration: {str(e)}")

    def update_key_config(self, key_id: str, name: str, comment: str, expire: str, git_configured: bool, github_configured: bool) -> None:
        """Update configuration for a GPG key."""
        config = {
            'gpg_installed': True,
            'key_configured': True,
            'git_configured': git_configured,
            'gpg_key_id': key_id,
            'github_key_added': github_configured
        }
        self.save_config(config)

    def get_key_config(self, key_id: str) -> Optional[Dict[str, Any]]:
        """Get configuration for a GPG key."""
        config = self.load_config()
        return config.get(key_id)

    def check_gpg_status(self) -> Dict[str, Any]:
        """Check the status of GPG configuration."""
        try:
            status = {
                'gpg_installed': self.check_gpg_installed(),
                # 'key_configured': False,
                # 'git_configured': False,
                # 'github_configured': False,
                # 'key_details': {},
                # 'github_key_details': {},
                # 'github_key_added': False,
                # 'last_update': None
            }

            if status['gpg_installed']:
                key_id = self.get_gpg_key_id()
                if key_id:
                    status['key_configured'] = True
                    status['key_details'] = self.get_gpg_key_details(key_id)
                    
                    # Check git configuration
                    try:
                        signing_key = subprocess.run(
                            ['git', 'config', '--get', 'user.signingkey'],
                            capture_output=True, text=True, check=True
                        ).stdout.strip()
                        if signing_key == key_id:
                            status['git_configured'] = True
                    except subprocess.CalledProcessError:
                        pass
                    
                    # Check GitHub configuration
                    try:
                        github_key_details = self.verify_github_key(key_id)
                        status['public_key'] = "\n"+"".join(github_key_details['public_key'])
                        status['github_configured'] = bool(github_key_details)
                    except Exception as e:
                        self.logger.error(f"Failed to verify GitHub key: {e}")
                        status['public_key'] = {}
                        status['github_configured'] = False

                    # Load config to get the latest status
                    config = self.load_config()
                    status.update({
                        'github_key_added': config.get('github_key_added', False),
                        'last_update': config.get('last_config_update', None)
                    })

            return status
        except Exception as e:
            self.logger.error(f"Failed to check GPG status: {e}")
            return {
                'error': str(e),
                'gpg_installed': False,
                'key_configured': False,
                'git_configured': False,
                'github_configured': False,
                'key_details': {},
                'github_key_added': False,
                'last_update': None
            }



    def get_gpg_key_id(self) -> Optional[str]:
        """Get the first available GPG secret key ID."""
        try:
            result = subprocess.run(['gpg', '--list-secret-keys', '--keyid-format=long'],
                                  capture_output=True, text=True, check=True)
            lines = result.stdout.split('\n')
            for line in lines:
                if line.startswith('sec'):
                    key_parts = line.split()
                    if len(key_parts) > 1:
                        key_id = key_parts[1].strip('[]')
                        # Extract just the key ID without algorithm prefix
                        return key_id.split('/')[-1]
            return None
        except subprocess.CalledProcessError:
            return None

    def get_gpg_key_details(self, key_id: str) -> Dict[str, Any]:
        """Get detailed information about a GPG key."""
        try:
            key_info = subprocess.run(['gpg', '--list-secret-keys', '--keyid-format=long'],
                                    capture_output=True, text=True, check=True)
            details = {}
            key_found = False
            subkey_found = False
            for line in key_info.stdout.split('\n'):
                if line.startswith('sec'):
                    key_parts = line.split()
                    if len(key_parts) > 1:
                        current_key = key_parts[1].strip('[]')
                        # Extract just the key ID without algorithm prefix
                        current_key_id = current_key.split('/')[-1]
                        if key_id == current_key_id:
                            key_found = True
                            details['primary_key'] = current_key_id
                            details['primary_type'] = key_parts[1].split('/')[0]
                            details['primary_size'] = key_parts[2]
                            details['primary_created'] = key_parts[3]
                elif key_found and line.startswith('uid'):
                    uid_parts = line.split('uid')[1].strip()
                    owner_parts = uid_parts.split(']')[-1].strip()
                    name_parts = owner_parts.split('<')[0].strip()
                    details['owner'] = name_parts
                elif key_found and line.startswith('ssb'):
                    subkey_parts = line.split()
                    if len(subkey_parts) > 2:
                        details['subkey_type'] = subkey_parts[1].split('/')[0]
                        details['subkey_size'] = subkey_parts[2]
                        if len(subkey_parts) > 3:
                            details['subkey_created'] = subkey_parts[3]
                        # if len(subkey_parts) > 4:
                        #     details['subkey_expires'] = subkey_parts[4]
            return details
        except subprocess.CalledProcessError as e:
            self.logger.error(f"Failed to get key details: {e}")
            return {}

    def delete_gpg_key(self, key_id: str) -> bool:
        """Delete a GPG key using its fingerprint."""
        try:
            # Get the full fingerprint first
            key_info = subprocess.run(['gpg', '--list-keys', '--with-colons', key_id],
                                    capture_output=True, text=True, check=True)
            fingerprint = None
            for line in key_info.stdout.split('\n'):
                if line.startswith('fpr:'):
                    fingerprint = line.split(':')[9]
                    break
            
            if not fingerprint:
                raise ValueError(f"Could not find fingerprint for key {key_id}")

            # Delete both secret and public key using fingerprint
            subprocess.run(['gpg', '--batch', '--yes', '--delete-secret-and-public-key', fingerprint],
                         capture_output=True, text=True, check=True)
            
            # Clear git configuration
            subprocess.run(['git', 'config', '--global', '--unset', 'user.signingkey'],
                         capture_output=True, text=True)
            subprocess.run(['git', 'config', '--global', '--unset', 'user.email'],
                         capture_output=True, text=True)
            subprocess.run(['git', 'config', '--global', '--unset', 'user.name'],
                         capture_output=True, text=True)
            
            # Clear our configuration
            self.clear_config()
            
            self.logger.info(f"Key {key_id} (fingerprint: {fingerprint}) deleted successfully")
            return True
        except subprocess.CalledProcessError as e:
            self.logger.error(f"Failed to delete GPG key: {e}")
            raise RuntimeError(f"Failed to delete GPG key: {e.stderr}")
        except Exception as e:
            self.logger.error(f"Error during key deletion: {e}")
            raise RuntimeError(f"Failed to delete GPG key: {str(e)}")

    def configure_git(self, key_id: str) -> bool:
        """Configure Git to use a specific GPG key for signing."""
        try:
            subprocess.run(['git', 'config', '--global', 'user.signingkey', key_id], check=True)
            subprocess.run(['git', 'config', '--global', 'commit.gpgsign', 'true'], check=True)
            return True
        except subprocess.CalledProcessError:
            self.logger.error(f"Failed to configure Git for key: {key_id}")
            return False

    def connect_github(self) -> bool:
        """Verify and configure GPG key with GitHub."""
        try:
            # Ask for GitHub PAT first
            print(Fore.CYAN + "\n🔍 Verifying GitHub GPG key configuration")
            print(Fore.YELLOW + "\n⚠️ Please Enter Your GitHub Personal Access Token(PAT) with read:gpg_key and write:gpg_key permissions.")
            print(Fore.YELLOW + "This token will be used to:")
            print(Fore.YELLOW + "1. Verify if the GPG key exists on GitHub")
            print(Fore.YELLOW + "2. If not, Then Add the GPG key to your GitHub account.")
            print(Fore.YELLOW + "3. If, already added Verify the key addition.")
            print(Fore.YELLOW + "4. If, the GPG key add doesn't have any WRITE scope, only validate using READ.")
            print(Fore.YELLOW + "\nRequired scopes: read:gpg_key(MANDATORY), write:gpg_key(OPTIONAL)")
            print(Fore.YELLOW + "Token will be used only for GPG key operations.", end="\n")
            token = input().strip()

            if not token:
                print(Fore.RED + "❌ GitHub PAT (minimum read:gpg_key ALLOWED) Token is Required for Verification.")
                return False

            # Set up headers for API requests
            headers = {
                'Accept': 'application/vnd.github+json',
                'Authorization': f'token {token}'
            }

            # Get GPG Key ID
            key_id = self.get_gpg_key_id()
            if not key_id:
                self.logger.error("No GPG key found")
                return False

            # Get key details first
            result = subprocess.run(
                ['gpg', '--with-colons', '--fingerprint', key_id],
                capture_output=True, text=True, check=True
            )
            lines = result.stdout.splitlines()
            fingerprint = ""
            uid_name = "Unknown"
            for line in lines:
                if line.startswith("fpr:"):
                    fingerprint = line.split(":")[9]
                elif line.startswith("uid:"):
                    uid_parts = line.split(":")
                    if len(uid_parts) >= 10:
                        uid_name = uid_parts[9]

            # Retrieve GitHub username from git config or prompt
            try:
                github_username = subprocess.run(
                    ['git', 'config', '--get', 'github.user'],
                    capture_output=True, text=True, check=True
                ).stdout.strip()
            except subprocess.CalledProcessError:
                github_username = ""

            if not github_username:
                try:
                    github_username = subprocess.run(
                        ['git', 'config', '--get', 'user.name'],
                        capture_output=True, text=True, check=True
                    ).stdout.strip()
                except subprocess.CalledProcessError:
                    pass

            if not github_username:
                print(Fore.YELLOW + "⚠️ GitHub username not found in git config.")
                print(Fore.YELLOW + "   Please enter your GitHub username:", end=" ")
                github_username = input().strip()
                if not github_username:
                    print(Fore.RED + "❌ GitHub username is required.")
                    return False

            # Step 3: Export full public key in ASCII-armored format
            try:
                export_result = subprocess.run(
                    ['gpg', '--armor', '--export', '--no-tty', '--batch', key_id],
                    capture_output=True, text=True, check=True
                )
                public_key = export_result.stdout.strip()
                key_id_hex = key_id.replace(' ', '').replace('/', '')
            except subprocess.CalledProcessError as e:
                self.logger.error(f"GPG export failed: {e.stderr}")
                return False

            # Step 4: Print the full public key line by line (avoids truncation)
            print(Fore.CYAN + "📜 Full GPG Public Key:")
            print(Fore.WHITE + "──────────────────────────────────────────────")
            for line in public_key.splitlines():
                print(Fore.WHITE + line)
            print(Fore.WHITE + "──────────────────────────────────────────────\n")

            # Step 5: Show GitHub manual upload instructions
            print(Fore.YELLOW + "📢 GitHub Setup Instructions:")
            print(Fore.YELLOW + "1. Copy the full public key above.")
            print(Fore.YELLOW + "2. Visit: https://github.com/settings/keys")
            print(Fore.YELLOW + "3. Click on 'New GPG key'.")
            print(Fore.YELLOW + "4. Paste the key into the field.")
            print(Fore.YELLOW + "5. Click 'Add GPG key'.")
            print(Fore.YELLOW + "\n" + Fore.CYAN + "⏳ Verification Timer (5 seconds):")
            print(Fore.YELLOW + "Please wait while we verify the key addition...")
            
            # Start verification timer
            timeout = 5  # 5 seconds
            end_time = datetime.now() + timedelta(seconds=timeout)
            
            while datetime.now() < end_time:
                remaining = int((end_time - datetime.now()).total_seconds())
                print(Fore.WHITE + f"\rTime remaining: {remaining} seconds...", end="")
                time.sleep(1)
            
            print("\n" + Fore.YELLOW + "\n❓ Verification Prompt:")
            print(Fore.YELLOW + "1. Have you completed adding the GPG key to GitHub?")
            print(Fore.YELLOW + "2. Would you like us to verify the key addition now?")
            print(Fore.YELLOW + "\nType 'y' to verify or 'n' to skip verification: ", end="")
            
            # Get user input with timeout
            try:
                import signal
                def handler(signum, frame):
                    raise TimeoutError
                
                signal.signal(signal.SIGALRM, handler)
                signal.alarm(30)  # 30 second timeout for input
                
                user_input = input().lower()
                signal.alarm(0)  # Reset the alarm
                
                if user_input == 'y':
                    # Verify if key exists first
                    response = requests.get(
                        f'https://api.github.com/users/{github_username}/gpg_keys',
                        headers=headers
                    )
                    
                    if response.status_code == 200:
                        existing_keys = response.json()
                        for gpg_key in existing_keys:
                            if gpg_key.get('key_id') == key_id_hex:
                                print(Fore.GREEN + "✅ GPG key already exists on GitHub!")
                                print(Fore.GREEN + f"Key ID: {key_id_hex}")
                                
                                # Update configuration
                                config = self.load_config()
                                config['github_key_added'] = True
                                config['github_configured'] = True
                                config['last_config_update'] = datetime.now().isoformat()
                                self.save_config(config)
                                return True
                    
                    # If key doesn't exist, add it automatically since we have write permissions
                    print(Fore.CYAN + "\n🔄 Adding GPG key to GitHub...")
                    print(Fore.YELLOW + "   Using provided token with write:gpg_key permissions to add the key")
                    
                    # Add the key to GitHub
                    add_key_response = requests.post(
                        f'https://api.github.com/user/gpg_keys',
                        headers=headers,
                        json={
                            'armored_public_key': public_key,
                            'title': f'GPG Key {key_id_hex[:8]} - {github_username}'
                        }
                    )
                    
                    if add_key_response.status_code == 201:
                        print(Fore.GREEN + "✅ GPG key successfully added to GitHub!")
                        print(Fore.GREEN + f"Key ID: {key_id_hex}")
                        print(Fore.GREEN + f"Title: GPG Key {key_id_hex[:8]} - {github_username}")
                        
                        # Update configuration
                        config = self.load_config()
                        config['github_key_added'] = True
                        config['github_configured'] = True
                        config['last_config_update'] = datetime.now().isoformat()
                        self.save_config(config)
                        return True
                    else:
                        error_msg = add_key_response.json().get('message', 'Unknown error')
                        print(Fore.RED + f"❌ Failed to add key: {error_msg}")
                        if 'read:gpg_key' in error_msg:
                            print(Fore.YELLOW + "💡 Hint: Make sure your token has write:gpg_key permissions")
                        return False
                
                elif user_input == 'n':
                    print(Fore.YELLOW + "⚠️ Skipping verification. You can verify later with './GPG-KeyManager.py -cg'.")
                    return False
                else:
                    print(Fore.RED + "Invalid input. Please type 'y' or 'n'.")
                    return False
            
            except TimeoutError:
                print(Fore.YELLOW + "\n⏰ Input timeout. Skipping verification.")
                return False

        except subprocess.CalledProcessError as e:
            self.logger.error(f"Subprocess error: {e.stderr}")
            raise RuntimeError(f"Failed to connect to GitHub: {e.stderr}")
        except Exception as e:
            self.logger.error(f"Unexpected error: {e}")
            raise RuntimeError(f"Failed to connect to GitHub: {str(e)}")

    def create_gpg_key(self, name: str, email: str, comment: str, expire: str) -> Optional[str]:
        """Create a new GPG key with the given parameters."""
        try:
            # Create a temporary file for the batch input
            import tempfile
            with tempfile.NamedTemporaryFile('w', delete=False) as temp:
                # Write the batch input file
                temp.write(f"""
                Key-Type: RSA
                Key-Length: 4096
                Subkey-Type: RSA
                Subkey-Length: 4096
                Name-Real: {name}
                Name-Email: {email}
                {f'Name-Comment: {comment}' if comment else ''}
                Expire-Date: {expire if expire != '0' else '0'}
                %no-protection
                %commit
                """)
                temp.flush()

                # Run the key creation command
                subprocess.run(
                    ['gpg', '--batch', '--pinentry-mode', 'loopback', '--gen-key', temp.name],
                    check=True,
                    capture_output=True,
                    text=True
                )

            # List keys to get the new key ID
            result = subprocess.run(
                ['gpg', '--list-secret-keys', '--with-colons'],
                check=True,
                capture_output=True,
                text=True
            )

            # Parse the output to find the newest key
            lines = result.stdout.splitlines()
            key_id = None
            for line in lines:
                if line.startswith("sec:"):  # secret key line
                    parts = line.split(":")
                    if len(parts) > 4:
                        key_id = parts[4]  # key ID is in the 5th field
                        break

            if not key_id:
                self.logger.error("Failed to get key ID from key list")
                return None

            # Configure git with the new key
            if self.configure_git(key_id):
                # Update configuration
                config = self.load_config()
                config['gpg_key_id'] = key_id
                config['git_configured'] = True
                config['git_email'] = email
                config['last_config_update'] = datetime.now().isoformat()
                config['key_creation_time'] = datetime.now().isoformat()
                self.save_config(config)

                print(Fore.GREEN + f"✅ Created new GPG key: {key_id}")
                print(Fore.GREEN + f"✓ Name: {name}")
                print(Fore.GREEN + f"✓ Email: {email}")
                if comment:
                    print(Fore.GREEN + f"✓ Comment: {comment}")
                if expire != '0':
                    print(Fore.GREEN + f"✓ Expires in: {expire} days")
                print(Fore.YELLOW + "\n💡 Git is now configured to use GPG signing!")
                print(Fore.YELLOW + "To sign a commit: git commit -S -m \"your message\"\n")
                return key_id
            else:
                return None

        except subprocess.CalledProcessError as e:
            self.logger.error(f"Failed to create GPG key: {e}")
            print(Fore.RED + f"❌ Failed to create GPG key: {e.stderr}")
            return None
        except Exception as e:
            keys = []
            current_key = None

            for line in result.stdout.splitlines():
                if line.startswith('sec:'):  # secret key line
                    if current_key:
                        keys.append(current_key)
                    current_key = {}
                    parts = line.split(':')
                    current_key['type'] = parts[1]
                    current_key['key_id'] = parts[4]
                    current_key['created'] = parts[5]
                    current_key['expires'] = parts[6]
                    current_key['uid'] = ''
                    current_key['configured'] = False  # Track if key is configured
                elif line.startswith('uid:') and current_key:
                    current_key['uid'] = line.split(':')[9]
                elif line.startswith('ssb:') and current_key:
                    subkey_parts = line.split(':')
                    current_key['subkey_type'] = subkey_parts[1]
                    current_key['subkey_id'] = subkey_parts[4]
                    current_key['subkey_size'] = subkey_parts[2]
                    if len(subkey_parts) > 3:
                        current_key['subkey_created'] = subkey_parts[3]

            if current_key:
                keys.append(current_key)

            # Check git configuration for each key
            try:
                git_key = subprocess.run(
                    ['git', 'config', '--get', 'user.signingkey'],
                    capture_output=True,
                    text=True,
                    check=True
                ).stdout.strip()
                
                for key in keys:
                    if key['key_id'] == git_key:
                        key['configured'] = True
                        key['git_email'] = subprocess.run(
                            ['git', 'config', '--get', 'user.email'],
                            capture_output=True,
                            text=True,
                            check=True
                        ).stdout.strip()
            except subprocess.CalledProcessError:
                pass

            # Print formatted list of keys
            print(Fore.CYAN + "\n📦 Available GPG Keys:")
            print(Fore.WHITE + "-" * 60)
            for i, key in enumerate(keys, 1):
                status = Fore.GREEN + "✓" if key['configured'] else Fore.RED + "✗"
                print(Fore.WHITE + f"\n{i}. Key: {key['uid']}")
                print(Fore.WHITE + f"   Key ID: {key['key_id']}")
                print(Fore.WHITE + f"   Type: {key['type']}")
                print(Fore.WHITE + f"   Length: {key['subkey_size']} bits")
                print(Fore.WHITE + f"   Created: {key['created']}")
                if key['expires'] != '0':
                    print(Fore.WHITE + f"   Expires: {key['expires']}")
                print(Fore.WHITE + f"   Status: {status} Configured")
                if key['configured']:
                    print(Fore.WHITE + f"   Git Email: {key['git_email']}")

            # If no keys are configured, prompt user
            if not any(key['configured'] for key in keys) and keys:
                print(Fore.YELLOW + "\n💡 No GPG keys are currently configured with git!")
                print(Fore.YELLOW + "Would you like to configure one of these keys with git?")
                choice = input(Fore.WHITE + "Enter key number to configure (or press Enter to skip): ").strip()
                if choice.isdigit() and 1 <= int(choice) <= len(keys):
                    selected_key = keys[int(choice) - 1]
                    print(Fore.CYAN + f"\n🔄 Configuring key {selected_key['key_id']}...")
                    if self.configure_git(selected_key['key_id']):
                        print(Fore.GREEN + "✅ Key configured successfully!")
                    else:
                        print(Fore.RED + "❌ Failed to configure key")

            return keys

        except subprocess.CalledProcessError as e:
            self.logger.error(f"Failed to list GPG keys: {e}")
            print(Fore.RED + f"❌ Failed to list GPG keys: {e.stderr}")
            return []
        except Exception as e:
            self.logger.error(f"Unexpected error listing GPG keys: {e}")
            print(Fore.RED + f"❌ Unexpected error: {e}")
            return []

    def git_config(self) -> bool:
        """Configure git GPG signing with a selected GPG key."""
        try:
            # List available GPG keys
            keys = self.list_gpg_keys()
            if not keys:
                print(Fore.RED + "❌ No GPG keys found. Please create one first with -ck")
                return False

            print(Fore.CYAN + "\n📦 Available GPG Keys:")
            for i, key in enumerate(keys, 1):
                print(Fore.WHITE + f"{i}. {key['uid']}")
                print(Fore.WHITE + f"   Key ID: {key['key_id']}")
                print(Fore.WHITE + f"   Type: {key['type']}")
                print(Fore.WHITE + f"   Length: {key['length']} bits")
                print(Fore.WHITE + f"   Created: {key['created']}")
                if key['expires'] != '0':
                    print(Fore.WHITE + f"   Expires: {key['expires']}")
                print(Fore.WHITE + "")

            print(Fore.YELLOW + "\nPlease select a GPG key number to configure with git:")
            print(Fore.YELLOW + "(Enter 0 to cancel)")
            
            try:
                choice = int(input().strip())
                if choice == 0:
                    print(Fore.YELLOW + "Operation cancelled")
                    return False
                if not (1 <= choice <= len(keys)):
                    print(Fore.RED + "❌ Invalid choice")
                    return False

                selected_key = keys[choice - 1]
                print(Fore.CYAN + "\n🔄 Configuring git with selected GPG key...")
                if self.configure_git(selected_key['key_id']):
                    print(Fore.GREEN + "✅ Git GPG configuration completed!")
                    print(Fore.GREEN + f"✓ Selected key: {selected_key['uid']}")
                    print(Fore.GREEN + f"✓ Key ID: {selected_key['key_id']}")
                    print(Fore.YELLOW + "\n💡 You can now sign your git commits with GPG!")
                    print(Fore.YELLOW + "To sign a commit: git commit -S -m \"your message\"\n")
                    
                    # Update configuration to set github_configured to True
                    config = self.load_config()
                    config['github_configured'] = True
                    config['last_config_update'] = datetime.now().isoformat()
                    self.save_config(config)
                    
                    return True
                else:
                    print(Fore.RED + "❌ Failed to configure git GPG")
                    return False

            except ValueError:
                print(Fore.RED + "❌ Please enter a valid number")
                return False

        except Exception as e:
            error_msg = f"Failed to configure git GPG: {str(e)}"
            self.logger.error(error_msg)
            print(Fore.RED + error_msg)
            return False

    def list_gpg_keys(self) -> None:
        """List all available GPG keys with detailed information."""
        try:
            # Get all secret keys with detailed information
            result = subprocess.run(['gpg', '--list-secret-keys', '--with-colons'],
                                capture_output=True, text=True, check=True)
            lines = result.stdout.split('\n')
            
            # Parse the key information
            current_key = None
            keys = []
            
            for line in lines:
                if not line:
                    continue
                
                parts = line.split(':')
                if parts[0] == 'sec':  # Start of a secret key
                    if current_key:
                        keys.append(current_key)
                    current_key = {
                        'type': 'secret',
                        'key_id': parts[4],
                        'created': parts[5],
                        'expires': parts[6],
                        'uid': '',
                        'status': ''
                    }
                elif parts[0] == 'uid':  # User ID line
                    if current_key:
                        current_key['uid'] = parts[9]  # Get the user ID
                        current_key['status'] = parts[1]  # Get the status flag
            
            if current_key:
                keys.append(current_key)
            
            if not keys:
                print(Fore.YELLOW + "No GPG keys found")
                return
            
            print(Fore.CYAN + "\n📦 Available GPG Keys:")
            print(Fore.WHITE + "-" * 80)
            
            for key in keys:
                print(Fore.GREEN + f"\nKey ID: {key['key_id']}")
                print(Fore.WHITE + f"Type: {key['type']}")
                print(Fore.WHITE + f"Created: {key['created']}")
                print(Fore.WHITE + f"Expires: {key['expires']}")
                print(Fore.WHITE + f"User ID: {key['uid']}")
                print(Fore.WHITE + f"Status: {key['status']}")
                
                # Check if this key is configured in git
                try:
                    git_signing_key = subprocess.run(
                        ['git', 'config', '--get', 'user.signingkey'],
                        capture_output=True, text=True, check=True
                    ).stdout.strip()
                    if git_signing_key == key['key_id']:
                        print(Fore.GREEN + "✓ Configured in git")
                    else:
                        print(Fore.YELLOW + "⚠ Not configured in git")
                except subprocess.CalledProcessError:
                    print(Fore.YELLOW + "⚠ Not configured in git")
                    
                print(Fore.WHITE + "-" * 80)
            
        except subprocess.CalledProcessError as e:
            self.logger.error(f"Error listing GPG keys: {e}")
            print(Fore.RED + f"❌ Error listing GPG keys: {e}")
            raise
