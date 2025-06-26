#!/usr/bin/env python3
"""
Script Logger - A utility to log shell script executions with timestamps and output capture.

This module provides a ScriptLogger class that can be used to log messages with timestamps,
and a command-line interface for logging shell script output.

Example usage as a module:
    from logger import ScriptLogger
    
    logger = ScriptLogger(log_file='app.log')
    logger.log('This is an info message', 'INFO')
    logger.log('This is an error', 'ERROR', 'RED')

Example usage from command line:
    # Log everything from this point
    exec > >(python3 -m logger --log-file=script.log) 2>&1
    
    # Or for a specific command:
    some_command | python3 -m logger --log-file=command.log
"""

import argparse
import datetime
import os
import signal
import sys
import time
from pathlib import Path
from typing import Optional, TextIO

# ANSI color codes for terminal output
COLORS = {
    'RESET': '\033[0m',
    'BLACK': '\033[30m',
    'RED': '\033[31m',
    'GREEN': '\033[32m',
    'YELLOW': '\033[33m',
    'BLUE': '\033[34m',
    'MAGENTA': '\033[35m',
    'CYAN': '\033[36m',
    'WHITE': '\033[37m',
}

class ScriptLogger:
    def __init__(
        self,
        log_file: str = None,
        timestamp_format: str = '%Y-%m-%d %H:%M:%S',
        max_log_size: int = 5 * 1024 * 1024,  # 5MB default max log size
        max_backups: int = 5,
    ):
        """Initialize the script logger.
        
        Args:
            log_file: Path to the log file. If None, logs to stderr.
            timestamp_format: Format string for timestamps.
            max_log_size: Maximum log file size in bytes before rotation.
            max_backups: Maximum number of backup log files to keep.
        """
        self.log_file = Path(log_file) if log_file else None
        self.timestamp_format = timestamp_format
        self.max_log_size = max_log_size
        self.max_backups = max_backups
        self._log_handle: Optional[TextIO] = None
        self._setup_logging()
        self._setup_signal_handlers()

    def _setup_logging(self) -> None:
        """Set up the log file and handle log rotation."""
        if not self.log_file:
            self._log_handle = sys.stderr
            return

        # Create log directory if it doesn't exist
        self.log_file.parent.mkdir(parents=True, exist_ok=True)

        # Rotate logs if needed
        if self.log_file.exists() and self.log_file.stat().st_size > self.max_log_size:
            self._rotate_logs()

        # Open log file in append mode
        self._log_handle = open(self.log_file, 'a', encoding='utf-8')

    def _rotate_logs(self) -> None:
        """Rotate log files."""
        if not self.log_file or not self.log_file.exists():
            return

        # Close current log file if it's open
        if self._log_handle and not self._log_handle.closed:
            self._log_handle.close()

        # Remove oldest backup if we've reached max_backups
        oldest_backup = self.log_file.with_suffix(f'.{self.max_backups}.log')
        if oldest_backup.exists():
            oldest_backup.unlink()

        # Rotate existing backups
        for i in range(self.max_backups - 1, 0, -1):
            old_backup = self.log_file.with_suffix(f'.{i}.log')
            if old_backup.exists():
                new_backup = self.log_file.with_suffix(f'.{i+1}.log')
                old_backup.rename(new_backup)

        # Rename current log to .1.log
        first_backup = self.log_file.with_suffix('.1.log')
        self.log_file.rename(first_backup)

    def _setup_signal_handlers(self) -> None:
        """Set up signal handlers for proper cleanup."""
        def signal_handler(signum, frame):
            self.cleanup()
            sys.exit(0)

        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)

    def get_timestamp(self) -> str:
        """Get current timestamp in the configured format."""
        return datetime.datetime.now().strftime(self.timestamp_format)

    def log(self, message: str, level: str = 'INFO', color: str = None) -> None:
        """Log a message with the specified level and optional color."""
        timestamp = self.get_timestamp()
        log_entry = f"[{timestamp}] [{level}] {message}"
        
        # Write to log file (without colors)
        if self._log_handle and not self._log_handle.closed:
            print(log_entry, file=self._log_handle, flush=True)
        
        # Write to stderr with colors if specified
        if color and color in COLORS:
            print(f"{COLORS[color]}{log_entry}{COLORS['RESET']}", file=sys.stderr)
        else:
            print(log_entry, file=sys.stderr, flush=True)

    def log_command(self, command: str) -> None:
        """Log a command that's about to be executed."""
        self.log(f"Executing: {command}", 'CMD', 'BLUE')

    def log_output(self, output: str) -> None:
        """Log command output."""
        for line in output.splitlines():
            self.log(f"  {line}", 'OUT', 'GREEN')

    def log_error(self, error: str) -> None:
        """Log an error message."""
        self.log(f"Error: {error}", 'ERROR', 'RED')

    def cleanup(self) -> None:
        """Clean up resources."""
        if self._log_handle and self._log_handle is not sys.stderr:
            self._log_handle.close()

def parse_args(args=None):
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description='Log shell script output with timestamps.')
    parser.add_argument('--log-file', help='Path to the log file')
    parser.add_argument('--max-size', type=int, default=5*1024*1024,
                        help='Maximum log file size in bytes (default: 5MB)')
    parser.add_argument('--max-backups', type=int, default=5,
                        help='Maximum number of backup logs to keep (default: 5)')
    return parser.parse_args(args)

def main(args=None):
    """Main entry point when used as a command-line tool."""
    args = parse_args(args)
    
    logger = ScriptLogger(
        log_file=args.log_file,
        max_log_size=args.max_size,
        max_backups=args.max_backups,
    )
    
    try:
        # Read from stdin and log each line
        for line in sys.stdin:
            logger.log(line.rstrip('\n'), 'OUTPUT', 'CYAN')
    except KeyboardInterrupt:
        logger.log("Logging interrupted by user", 'WARNING', 'YELLOW')
        return 130  # Standard exit code for SIGINT
    except Exception as e:
        logger.log_error(f"Error in logger: {str(e)}")
        return 1
    finally:
        logger.cleanup()
    return 0

if __name__ == '__main__':
    sys.exit(main())
