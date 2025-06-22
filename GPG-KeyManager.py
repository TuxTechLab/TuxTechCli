#!/usr/bin/env python3

# Version information
__version__ = '1.0.0'
__version_info__ = {
    'version': __version__,
    'release_date': '2025-06-18',
    'version_history': {
        '1.0.0': {
            'release_date': '2025-06-18',
            'changes': [
                'Initial release',
                'Added GPG key creation with expiration support',
                'Added key listing functionality',
                'Added key deletion functionality',
                'Added key rotation functionality',
                'Added configuration status checking',
                'Added colorized output support',
                'Added debug mode support'
            ]
        }
    }
}

import os
import subprocess
import sys
from typing import Optional, Dict, Any
import argparse
import json
from colorama import init, Fore, Style

# Initialize colorama for cross-platform color support
init(autoreset=True)

# Import GPGKeyManager
from gpg_key_manager_core import GPGKeyManager

def main():
    """Main function to handle command line arguments."""
    try:
        # Create parser
        parser = argparse.ArgumentParser(
            description='TuxTechLabs GPG Key Manager',
            formatter_class=argparse.RawTextHelpFormatter
        )
        
        # Add version option
        parser.add_argument('-v', '--version', action='version', version=__version__)
        parser.add_argument('-vh', '--verbose-help', action='store_true',
                           help='Show detailed help message')
        
        # Create key arguments
        create_key_group = parser.add_argument_group('Create Key Options')
        create_key_group.add_argument('-ck', '--create-key', action='store_true',
                           help='Create a new GPG key')
        create_key_group.add_argument('--name', type=str,
                           help='Name for the GPG key (required with --create-key)')
        create_key_group.add_argument('--email', type=str,
                           help='Email for the GPG key (required with --create-key)')
        create_key_group.add_argument('--comment', type=str,
                           help='Comment for the GPG key (optional)')
        create_key_group.add_argument('--expire', type=str,
                           help='Expiration time for the key (optional, format: days/months/years)')
        
        # Other commands
        parser.add_argument('-lk', '--list-keys', action='store_true',
                           help='List all GPG keys')
        parser.add_argument('-dk', '--delete-key', action='store_true',
                           help='Delete a GPG key')
        parser.add_argument('-gc', '--git-config', action='store_true',
                           help='Configure git with a GPG key')
        parser.add_argument('-sc', '--status-check', action='store_true',
                           help='Check GPG configuration status')
        parser.add_argument('-cg', '--connect-github', action='store_true',
                           help='Connect GPG key with GitHub')
        parser.add_argument('-cc', '--clear-config', action='store_true',
                           help='Clear all configuration')
        
        # Key ID argument
        parser.add_argument('-k', '--key-id', type=str,
                           help='Specify the GPG key ID to use')

        # Parse arguments
        args = parser.parse_args()

        # Handle verbose help
        if args.verbose_help:
            print("\nTuxTechLabs GPG Key Manager v" + __version__)
            print("Release Date: " + __version_info__['release_date'])
            print("https://github.com/TuxTechLab")
            print("-" * 60)
            print("\nAvailable Commands:")
            print("-ck, --create-key\tCreate a new GPG key")
            print("\t--name\tName for the GPG key")
            print("\t--email\tEmail for the GPG key")
            print("\t--comment\tComment for the GPG key")
            print("\t--expire\tExpiration time for the key")
            print("-lk, --list-keys\tList all GPG keys")
            print("-dk, --delete-key\tDelete a GPG key")
            print("-gc, --git-config\tConfigure git with a GPG key")
            print("-sc, --status-check\tCheck GPG configuration status")
            print("-cg, --connect-github\tConnect GPG key with GitHub")
            print("-cc, --clear-config\tClear all configuration")
            print("-k, --key-id\t\tSpecify the GPG key ID to use")
            print("\nExample Usage:")
            print("./GPG-KeyManager.py -ck --name \"John Doe\" --email john@example.com")
            print("./GPG-KeyManager.py -gc -k KEY_ID")
            print("./GPG-KeyManager.py -lk")
            print("./GPG-KeyManager.py -sc")
            sys.exit(0)

        # Create manager instance
        manager = GPGKeyManager()

        # Check if GPG is installed
        if not manager.check_gpg_installed():
            print(Fore.RED + "Error: GPG is not installed on your system")
            print("Please install GPG first before using this script")
            sys.exit(1)

        # Execute the requested command
        if args.create_key:
            # Get required parameters either from args or user input
            args.name = args.name or input(Fore.CYAN + "Enter your name for the GPG key: ")
            args.email = args.email or input(Fore.CYAN + "Enter your email for the GPG key: ")
            args.comment = args.comment or input(Fore.CYAN + "Enter comment for the key (optional): ")
            args.expire = args.expire or input(Fore.CYAN + "Enter expiration time (days/months/years, optional): ")

            # Create the key
            result = manager.create_gpg_key(args.name, args.email, args.comment or "", args.expire or "")
            if result:
                print(Fore.GREEN + f"✅ GPG key created successfully: {result}")
            else:
                print(Fore.RED + "❌ Failed to create GPG key")
        elif args.list_keys:
            manager.list_gpg_keys()
        elif args.delete_key:
            if not args.key_id:
                print(Fore.RED + "Error: --key-id is required with --delete-key")
                sys.exit(1)
            if manager.delete_gpg_key(args.key_id):
                print(Fore.GREEN + "✅ GPG key deleted successfully")
            else:
                print(Fore.RED + "❌ Failed to delete GPG key")
        elif args.git_config:
            if not args.key_id:
                # List available GPG keys and prompt for selection
                print("\nAvailable GPG Keys:")
                manager.list_gpg_keys()
                
                key_id = input("\nEnter the key ID you want to configure with git: ").strip()
                if not key_id:
                    print("Error: No key ID provided")
                    sys.exit(1)
            else:
                key_id = args.key_id
                
            # Configure git with the selected key
            if manager.configure_git(key_id):
                print(Fore.GREEN + "✅ Git configuration successful")
                
                # Update configuration status
                status = manager.check_gpg_status()
                if status:
                    print("\nPGP Public Key:")
                    print("-" * 80)
                    print(status.get('key_details', {}).get('public_key', ''))
                    print("-" * 80)
                    
                    print("\nGPG Configuration Status:")
                    print("-" * 80)
                    
                    for key, value in status.items():
                        if key == 'git_configured':
                            color = Fore.GREEN if value else Fore.YELLOW
                            print(f"{color}{key}: {value}")
                        elif key == 'key_details':
                            # Skip key_details as we already showed the public key
                            continue
                        else:
                            print(Fore.WHITE + f"{key}: {value}")
                    print(Fore.WHITE + "-" * 80)
            else:
                print(Fore.RED + "❌ Failed to configure git")
        elif args.status_check:
            status = manager.check_gpg_status()
            
            # Print status information
            print("\nGPG Configuration Status:")
            print("-" * 80)
            
            # Print boolean status flags
            for flag in ['gpg_installed', 'key_configured', 'git_configured', 'github_configured']:
                value = status.get(flag, False)
                color = Fore.GREEN if value else Fore.YELLOW
                print(f"{color}{flag}: {value}")
            
            # Print key details
            key_details = status.get('key_details', {})
            print(Fore.WHITE + "key_details: {")
            for key, value in key_details.items():
                print(Fore.WHITE + f"    '{key}': '{value}'")
            print(Fore.WHITE + "}")
            
            # Print public key
            print(Fore.WHITE + "public_key:")
            print("-" * 80)
            print(status.get('public_key', ""))
            print("-" * 80)
            
            # Print github status
            print(Fore.WHITE + f"github_key_added: {status.get('github_key_added', False)}")
            print(Fore.WHITE + f"last_update: {status.get('last_update', '')}")
            print("-" * 80)
        elif args.connect_github:
            if not args.key_id:
                # List available GPG keys and prompt for selection
                print("\nAvailable GPG Keys:")
                manager.list_gpg_keys()
                
                key_id = input("\nEnter the key ID you want to connect with GitHub: ").strip()
                if not key_id:
                    print("Error: No key ID provided")
                    sys.exit(1)
            else:
                key_id = args.key_id
                
            if manager.connect_to_github(key_id):
                print(Fore.GREEN + "✅ GitHub connection successful")
            else:
                print(Fore.RED + "❌ Failed to connect to GitHub")
        elif args.clear_config:
            manager.clear_config()
            print(Fore.GREEN + "✅ Configuration cleared successfully")
        else:
            parser.print_help()
            sys.exit(1)

        sys.exit(0)

    except Exception as e:
        print(Fore.RED + f"❌ Error: {str(e)}")
        sys.exit(1)

        # # Handle commands
        # if args.git_config:
        #     result = manager.git_config()
        #     if result:
        #         print(Fore.GREEN + "✅ Git configuration completed successfully")
        #     else:
        #         print(Fore.RED + "❌ Failed to configure git")
        #         sys.exit(1)
        # elif args.create_key:
        #     result = manager.create_gpg_key()
        #     if not result:
        #         print(Fore.RED + "❌ Failed to create GPG key")
        #         sys.exit(1)
        # elif args.list_keys:
        #     keys = manager.list_gpg_keys()
        #     if keys:
        #         print(Fore.CYAN + "\n📦 Available GPG Keys:")
        #         for key in keys:
        #             print(Fore.WHITE + f"Key ID: {key['key_id']}")
        #             print(Fore.WHITE + f"Name: {key['uid']}")
        #             print(Fore.WHITE + f"Type: {key['type']}")
        #             print(Fore.WHITE + f"Length: {key['length']} bits")
        #             print(Fore.WHITE + f"Created: {key['created']}")
        #             if key['expires'] != '0':
        #                 print(Fore.WHITE + f"Expires: {key['expires']}")
        #             print(Fore.WHITE + "")
        #     else:
        #         print(Fore.YELLOW + "No GPG keys found")
        # elif args.delete_key:
        #     if args.key_id:
        #         result = manager.delete_gpg_key(args.key_id)
        #         if result:
        #             print(Fore.GREEN + f"✅ Deleted key: {args.key_id}")
        #         else:
        #             print(Fore.RED + f"❌ Failed to delete key: {args.key_id}")
        #             sys.exit(1)
        #     else:
        #         print(Fore.RED + "❌ Please specify a key ID with -k")
        #         sys.exit(1)
        #     if status['github_key_details']:
        #         print(Fore.WHITE + "\nGitHub Key Details:")
        #         for k, v in status['github_key_details'].items():
        #             print(Fore.WHITE + f"{k}: {v}")
        # elif args.connect_github:
        #     result = manager.connect_github()
        #     if result:
        #         print(Fore.GREEN + "✅ GitHub connection completed")
        #     else:
        #         print(Fore.RED + "❌ Failed to connect to GitHub")
        #         sys.exit(1)
        # else:
        #     parser.print_help()
        #     sys.exit(1)

    except Exception as e:
        print(Fore.RED + f"❌ Error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
