use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};
use std::process::Command;

/// Maximum allowed path length to prevent DoS
const MAX_PATH_LENGTH: usize = 4096;

/// Scan options passed from the UI
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScanOptions {
    pub repo: String,
    pub format: String,
}

/// Sync-check options passed from the UI
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncCheckOptions {
    pub repo: String,
    pub format: String,
}

/// Scan result returned from the CLI
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScanResult {
    pub success: bool,
    pub output: String,
    pub exit_code: i32,
    pub error: Option<String>,
}

/// Error types for validation failures
#[derive(Debug)]
pub enum ValidationError {
    EmptyPath,
    PathTooLong,
    InvalidCharacters,
    PathTraversal,
    NotFound,
    NotDirectory,
}

impl std::fmt::Display for ValidationError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ValidationError::EmptyPath => write!(f, "Repository path cannot be empty"),
            ValidationError::PathTooLong => write!(f, "Repository path exceeds maximum length"),
            ValidationError::InvalidCharacters => write!(f, "Repository path contains invalid characters"),
            ValidationError::PathTraversal => write!(f, "Repository path contains path traversal sequences"),
            ValidationError::NotFound => write!(f, "Repository path does not exist"),
            ValidationError::NotDirectory => write!(f, "Repository path is not a directory"),
        }
    }
}

impl std::error::Error for ValidationError {}

impl From<ValidationError> for String {
    fn from(err: ValidationError) -> String {
        err.to_string()
    }
}

/// Validate that a path string is safe to use
fn validate_path_string(path: &str) -> Result<(), ValidationError> {
    // Check for empty path
    if path.trim().is_empty() {
        return Err(ValidationError::EmptyPath);
    }

    // Check path length
    if path.len() > MAX_PATH_LENGTH {
        return Err(ValidationError::PathTooLong);
    }

    // Check for null bytes (prevents various attacks)
    if path.contains('\0') {
        return Err(ValidationError::InvalidCharacters);
    }

    // Check for path traversal attempts
    if path.contains("..") || path.contains("~/") {
        return Err(ValidationError::PathTraversal);
    }

    // Check for suspicious patterns
    if path.starts_with('/') && path.contains("/../") {
        return Err(ValidationError::PathTraversal);
    }

    Ok(())
}

/// Validate and canonicalize a repository path
fn validate_repo_path(path: &str) -> Result<PathBuf, ValidationError> {
    // First validate the string itself
    validate_path_string(path)?;

    let path_obj = Path::new(path);

    // Canonicalize to resolve any symlinks or relative components
    let canonical = path_obj
        .canonicalize()
        .map_err(|_| ValidationError::NotFound)?;

    // Verify the canonical path still exists
    if !canonical.exists() {
        return Err(ValidationError::NotFound);
    }

    // Verify it's a directory
    if !canonical.is_dir() {
        return Err(ValidationError::NotDirectory);
    }

    Ok(canonical)
}

/// Get the node executable and CLI script paths
fn get_cli_paths() -> Result<(PathBuf, PathBuf), String> {
    let exe_path = std::env::current_exe()
        .map_err(|e| format!("Failed to get executable path: {}", e))?;

    // Get the directory containing the Tauri app executable
    let exe_dir = exe_path
        .parent()
        .ok_or_else(|| "Invalid executable path".to_string())?;

    // The CLI script is at skillsctl (symlink to ../../../packages/cli/dist/cli.js)
    let cli_script = exe_dir.join("skillsctl");

    // Verify the CLI script exists
    if !cli_script.exists() {
        return Err(format!("CLI script not found at: {:?}", cli_script));
    }

    // For development, look for node in mise/bin directory
    // For production, this should be bundled with the app
    let node_path = which::which("node")
        .map_err(|_| "Node.js executable not found. Please ensure Node.js is installed.".to_string())?;

    Ok((node_path, cli_script))
}

/// Validate format parameter
fn validate_format(format: &str) -> Result<(), String> {
    if matches!(format, "json" | "text") {
        Ok(())
    } else {
        Err("Format must be 'json' or 'text'".to_string())
    }
}

/// Run a scan command via the CLI
#[tauri::command]
async fn run_scan(options: ScanOptions) -> Result<ScanResult, String> {
    // Validate format first
    if let Err(e) = validate_format(&options.format) {
        return Ok(ScanResult {
            success: false,
            output: String::new(),
            exit_code: 1,
            error: Some(e),
        });
    }

    // Validate and canonicalize the repository path
    let validated_path = match validate_repo_path(&options.repo) {
        Ok(path) => path,
        Err(e) => {
            return Ok(ScanResult {
                success: false,
                output: String::new(),
                exit_code: 1,
                error: Some(e.to_string()),
            });
        }
    };

    // Get the validated CLI paths (node and script)
    let (node_path, cli_script) = match get_cli_paths() {
        Ok(paths) => paths,
        Err(e) => {
            return Ok(ScanResult {
                success: false,
                output: String::new(),
                exit_code: 1,
                error: Some(e),
            });
        }
    };

    // Build the command: node <cli_script> scan --repo <path> --format <format> --no-save
    let output = Command::new(&node_path)
        .arg(&cli_script)
        .arg("scan")
        .arg("--repo")
        .arg(&validated_path)
        .arg("--format")
        .arg(&options.format)
        .arg("--no-save")
        .output();

    match output {
        Ok(result) => {
            let stdout = String::from_utf8_lossy(&result.stdout).to_string();
            let stderr = String::from_utf8_lossy(&result.stderr).to_string();
            let exit_code = result.status.code().unwrap_or(1);

            // For a scanner, exit code 0 or 1 are both "success" (1 = findings found)
            // Only treat as failure if exit code >= 2 (actual error) or stderr has content
            let success = exit_code < 2 && stderr.is_empty();

            Ok(ScanResult {
                success,
                output: stdout,
                exit_code,
                error: if !stderr.is_empty() { Some(stderr) } else { None },
            })
        }
        Err(e) => Ok(ScanResult {
            success: false,
            output: String::new(),
            exit_code: 1,
            error: Some(format!("Failed to run scan: {}", e)),
        }),
    }
}

/// Run a sync-check command via the CLI
#[tauri::command]
async fn run_sync_check(options: SyncCheckOptions) -> Result<ScanResult, String> {
    // Validate format first
    if let Err(e) = validate_format(&options.format) {
        return Ok(ScanResult {
            success: false,
            output: String::new(),
            exit_code: 1,
            error: Some(e),
        });
    }

    // Validate and canonicalize the repository path
    let validated_path = match validate_repo_path(&options.repo) {
        Ok(path) => path,
        Err(e) => {
            return Ok(ScanResult {
                success: false,
                output: String::new(),
                exit_code: 1,
                error: Some(e.to_string()),
            });
        }
    };

    // Get the validated CLI paths (node and script)
    let (node_path, cli_script) = match get_cli_paths() {
        Ok(paths) => paths,
        Err(e) => {
            return Ok(ScanResult {
                success: false,
                output: String::new(),
                exit_code: 1,
                error: Some(e),
            });
        }
    };

    // Build the command: node <cli_script> sync-check --repo <path> --format <format>
    let output = Command::new(&node_path)
        .arg(&cli_script)
        .arg("sync-check")
        .arg("--repo")
        .arg(&validated_path)
        .arg("--format")
        .arg(&options.format)
        .output();

    match output {
        Ok(result) => {
            let stdout = String::from_utf8_lossy(&result.stdout).to_string();
            let stderr = String::from_utf8_lossy(&result.stderr).to_string();
            let exit_code = result.status.code().unwrap_or(1);

            // For a scanner, exit code 0 or 1 are both "success" (1 = findings found)
            // Only treat as failure if exit code >= 2 (actual error) or stderr has content
            let success = exit_code < 2 && stderr.is_empty();

            Ok(ScanResult {
                success,
                output: stdout,
                exit_code,
                error: if !stderr.is_empty() { Some(stderr) } else { None },
            })
        }
        Err(e) => Ok(ScanResult {
            success: false,
            output: String::new(),
            exit_code: 1,
            error: Some(format!("Failed to run sync-check: {}", e)),
        }),
    }
}

/// Get scan history from the CLI
#[tauri::command]
async fn get_scan_history(repo: Option<String>, limit: Option<usize>) -> Result<String, String> {
    let (node_path, cli_script) = get_cli_paths()?;

    // Validate limit if provided
    let validated_limit = limit.unwrap_or(50).min(1000);
    if validated_limit > 1000 {
        return Err("Limit cannot exceed 1000".to_string());
    }

    let mut cmd = Command::new(&node_path);
    cmd.arg(&cli_script);
    cmd.arg("history");
    cmd.arg("--format").arg("json");
    cmd.arg("--limit").arg(validated_limit.to_string());

    if let Some(r) = repo {
        // Validate the repo path
        validate_path_string(&r)?;
        let validated_path = validate_repo_path(&r)?;
        cmd.arg("--repo").arg(validated_path);
    }

    let output = cmd.output();

    match output {
        Ok(result) => {
            let stdout = String::from_utf8_lossy(&result.stdout).to_string();
            Ok(stdout)
        }
        Err(e) => Err(format!("Failed to get history: {}", e)),
    }
}

/// Get scan statistics for a repository
#[tauri::command]
async fn get_scan_stats(repo: String) -> Result<String, String> {
    // Validate the repo path
    let validated_path = validate_repo_path(&repo)?;

    let (node_path, cli_script) = get_cli_paths()?;

    let output = Command::new(&node_path)
        .arg(&cli_script)
        .arg("stats")
        .arg("--repo")
        .arg(&validated_path)
        .output();

    match output {
        Ok(result) => {
            let stdout = String::from_utf8_lossy(&result.stdout).to_string();
            Ok(stdout)
        }
        Err(e) => Err(format!("Failed to get stats: {}", e)),
    }
}

// Include tests module when building with tests
#[cfg(test)]
include!("lib_tests.rs");

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .setup(|app| {
            if cfg!(debug_assertions) {
                app.handle().plugin(
                    tauri_plugin_log::Builder::default()
                        .level(log::LevelFilter::Info)
                        .build(),
                )?;
            }
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            run_scan,
            run_sync_check,
            get_scan_history,
            get_scan_stats,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
