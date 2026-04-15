import os
import subprocess

def copy_pub_key_to_clipboard_windows(key_path):
    """
    Reads the public key file and copies its content to the Windows clipboard.
    """
    pub_key_path = f"{key_path}.pub"
    
    if not os.path.exists(pub_key_path):
        print(f"Error: Public key not found at {pub_key_path}")
        return

    try:
        # Read the content of the public key file
        with open(pub_key_path, 'r') as f:
            public_key = f.read()
        
        # Use subprocess to run the 'clip' command, passing the key content as input
        subprocess.run('clip', input=public_key, text=True, check=True)
        
        print("\nSuccess: The public key has been copied to your clipboard.")
        
    except (FileNotFoundError, subprocess.CalledProcessError) as e:
        print(f"\nError: Could not copy key to clipboard. Error: {e}")
        print("You can copy the key manually from the file below:")
        with open(pub_key_path, 'r') as f:
            print(f.read())


def create_ssh_key_if_not_exists():
    """
    Checks for a default SSH key and creates it if it doesn't exist.
    """
    # Get the user's home directory and define the key path
    home_dir = os.path.expanduser('~')
    ssh_dir = os.path.join(home_dir, '.ssh')
    key_path = os.path.join(ssh_dir, 'id_rsa')

    # A. Check if the key already exists
    if os.path.exists(key_path):
        print(f"SSH key already exists at: {key_path}")
        print("Make sure this public key is added to your Git.")
        copy_pub_key_to_clipboard_windows(key_path)
        return

    # B. If the key doesn't exist, create it
    print("SSH key not found. Proceeding to create a new one.")

    # Create the .ssh directory if it doesn't exist
    if not os.path.isdir(ssh_dir):
        print(f"Creating directory: {ssh_dir}")
        os.makedirs(ssh_dir, mode=0o700) # Set secure permissions

    # Generate the SSH key using the ssh-keygen command
    try:
        command = [
            'ssh-keygen',
            '-t', 'rsa',      # Key type
            '-b', '4096',     # Key strength in bits
            '-f', key_path,   # File path to save the key
            '-N', ""          # No passphrase
        ]
        
        # Run the command, hiding its output unless there's an error
        subprocess.run(command, check=True, capture_output=True, text=True)
        
        print(f"\nSuccessfully created a new SSH key at: {key_path}")
        copy_pub_key_to_clipboard_windows(key_path)

    except FileNotFoundError:
        print("\nError: 'ssh-keygen' command not found. Is OpenSSH installed and in your system's PATH?")
    except subprocess.CalledProcessError as e:
        print("\nError during ssh-keygen execution:")
        print(e.stderr)

if __name__ == "__main__":
    create_ssh_key_if_not_exists()
