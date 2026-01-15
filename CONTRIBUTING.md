# Contributing to Remote Dev Environment

Thank you for your interest in contributing! This project relies on a combination of Docker, Shell scripts, and XFCE/XRDP configurations.

## 🛠️ Project Structure
*   `dockerfile`: The core image definition (generated from `dockerfile.example`).
*   `admin/`: Management scripts (`deploy_update.sh`, `manage_users.sh`, etc.).
*   `logs/`: Build and update logs.
*   `backups/`: User home directory backups.

## 🚀 Getting Started

1.  **Fork and Clone** the repository.
2.  **Initialize the Environment**:
    ```bash
    ./admin/deploy_update.sh
    ```
    This will build the base image and ensure all dependencies are met.

## 🧪 How to Test Changes

### Testing Dockerfile Changes
1.  Modify `dockerfile`.
2.  Rebuild the image:
    ```bash
    ./admin/deploy_update.sh
    ```
3.  Verify the new tool/configuration appears in your user container.
4.  **Check Logs**: If the build fails or hangs, review the detailed build logs in the `logs/` directory:
    ```bash
    cat logs/build-<timestamp>.log
    ```

### Testing Admin Scripts
*   Create a test user to verify script logic:
    ```bash
    ./admin/manage_users.sh add testuser
    ```
*   Connect via RDP (default port `3400`) to visually verify desktop changes.

## 📋 Pull Request Process
1.  Ensure your code follows the existing style (ShellCheck for scripts).
2.  Update `README.md` if you are adding new features or changing workflows.
3.  Describe your changes clearly in the Pull Request description.
