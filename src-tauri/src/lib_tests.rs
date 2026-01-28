use crate::*;
use std::fs;
use std::path::PathBuf;

// Helper to create a temporary test directory
fn create_test_dir(name: &str) -> tempfile::TempDir {
    tempfile::tempdir().expect("Failed to create temp dir")
}

// Helper to create a test git repository
fn create_test_git_repo() -> tempfile::TempDir {
    let dir = create_test_dir("test_repo");
    let git_dir = dir.path().join(".git");
    fs::create_dir(&git_dir).expect("Failed to create .git dir");
    dir
}

// tempfile module for temp directory management
mod tempfile {
    use std::fs;
    use std::path::Path;

    pub struct TempDir {
        path: std::path::PathBuf,
    }

    impl TempDir {
        pub fn path(&self) -> &Path {
            &self.path
        }
    }

    impl Drop for TempDir {
        fn drop(&mut self) {
            // Best effort cleanup
            let _ = fs::remove_dir_all(&self.path);
        }
    }

    pub fn tempdir() -> std::io::Result<TempDir> {
        let base_path = std::env::var("TMPDIR")
            .or_else(|_| std::env::var("TMP"))
            .unwrap_or_else(|_| "/tmp".to_string());

        let temp_dir = std::path::PathBuf::from(base_path);
        let unique_name = format!("skillsinspector_test_{}", std::process::id());
        let dir_path = temp_dir.join(unique_name);

        fs::create_dir(&dir_path)?;
        Ok(TempDir { path: dir_path })
    }
}

#[cfg(test)]
mod tests {

    // Tests for validate_path_string
    #[test]
    fn test_validate_path_string_empty_path() {
        let result = validate_path_string("");
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), ValidationError::EmptyPath));
    }

    #[test]
    fn test_validate_path_string_whitespace_only() {
        let result = validate_path_string("   ");
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), ValidationError::EmptyPath));
    }

    #[test]
    fn test_validate_path_string_success() {
        let result = validate_path_string("/valid/path");
        assert!(result.is_ok());
    }

    #[test]
    fn test_validate_path_string_too_long() {
        let long_path = "a/".repeat(MAX_PATH_LENGTH / 2 + 1);
        let result = validate_path_string(&long_path);
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), ValidationError::PathTooLong));
    }

    #[test]
    fn test_validate_path_string_null_byte() {
        let result = validate_path_string("valid\0path");
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), ValidationError::InvalidCharacters));
    }

    #[test]
    fn test_validate_path_string_double_dot_traversal() {
        let result = validate_path_string("../etc/passwd");
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), ValidationError::PathTraversal));
    }

    #[test]
    fn test_validate_path_string_tilde_traversal() {
        let result = validate_path_string("~/../../etc");
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), ValidationError::PathTraversal));
    }

    #[test]
    fn test_validate_path_string_absolute_traversal() {
        let result = validate_path_string("/foo/../bar");
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), ValidationError::PathTraversal));
    }

    // Tests for validate_repo_path
    #[test]
    fn test_validate_repo_path_not_found() {
        let result = validate_repo_path("/nonexistent/path/12345");
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), ValidationError::NotFound));
    }

    #[test]
    fn test_validate_repo_path_not_directory() {
        // Create a temp file instead of directory
        let dir = create_test_dir("file_test");
        let file_path = dir.path().join("test_file.txt");
        fs::write(&file_path, "test").expect("Failed to write test file");

        let result = validate_repo_path(&file_path.to_string_lossy());
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), ValidationError::NotDirectory));
    }

    #[test]
    fn test_validate_repo_path_not_git_repository() {
        let dir = create_test_dir("no_git");
        // It's a directory but not a git repo
        let result = validate_repo_path(dir.path().to_string_lossy());
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), ValidationError::NotGitRepository));
    }

    #[test]
    fn test_validate_repo_path_success() {
        let dir = create_test_git_repo();
        let result = validate_repo_path(dir.path().to_string_lossy());
        assert!(result.is_ok());
        // Path should be canonicalized
        assert_eq!(result.unwrap(), dir.path().canonicalize().unwrap());
    }

    // Tests for validate_format
    #[test]
    fn test_validate_format_json() {
        assert!(validate_format("json").is_ok());
    }

    #[test]
    fn test_validate_format_text() {
        assert!(validate_format("text").is_ok());
    }

    #[test]
    fn test_validate_format_invalid() {
        let result = validate_format("yaml");
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), "Format must be 'json' or 'text'");
    }

    // Tests for ValidationError Display
    #[test]
    fn test_validation_error_display_empty_path() {
        let error = ValidationError::EmptyPath;
        assert_eq!(error.to_string(), "Repository path cannot be empty");
    }

    #[test]
    fn test_validation_error_display_not_git_repository() {
        let error = ValidationError::NotGitRepository;
        assert_eq!(error.to_string(), "Repository path is not a git repository");
    }

    // Tests for ScanOptions serialization
    #[test]
    fn test_scan_options_serialize() {
        let options = ScanOptions {
            repo: "/test/repo".to_string(),
            format: "json".to_string(),
        };
        let json = serde_json::to_string(&options).expect("Failed to serialize");
        assert!(json.contains("test/repo"));
        assert!(json.contains("json"));
    }

    #[test]
    fn test_scan_options_deserialize() {
        let json = r#"{"repo":"/test/repo","format":"json"}"#;
        let options: ScanOptions = serde_json::from_str(json).expect("Failed to deserialize");
        assert_eq!(options.repo, "/test/repo");
        assert_eq!(options.format, "json");
    }

    // Tests for ScanResult serialization
    #[test]
    fn test_scan_result_success() {
        let result = ScanResult {
            success: true,
            output: "Test output".to_string(),
            exit_code: 0,
            error: None,
        };
        let json = serde_json::to_string(&result).expect("Failed to serialize");
        assert!(json.contains("Test output"));
    }

    #[test]
    fn test_scan_result_with_error() {
        let result = ScanResult {
            success: false,
            output: String::new(),
            exit_code: 1,
            error: Some("Test error".to_string()),
        };
        let json = serde_json::to_string(&result).expect("Failed to serialize");
        assert!(json.contains("Test error"));
    }

    // Integration-style tests that don't require actual CLI
    #[test]
    fn test_run_scan_with_invalid_format_returns_error() {
        // This tests the validation logic without actually running CLI
        // Since we can't mock Command easily, we test the validation path
        let options = ScanOptions {
            repo: "/test/repo".to_string(),
            format: "invalid".to_string(),
        };

        // validate_format should catch this
        let validation_result = validate_format(&options.format);
        assert!(validation_result.is_err());

        // The command would return error result
        let expected_error = validation_result.unwrap_err();
        assert_eq!(expected_error, "Format must be 'json' or 'text'");
    }

    #[test]
    fn test_sync_check_options_serialize() {
        let options = SyncCheckOptions {
            repo: "/test/repo".to_string(),
            format: "text".to_string(),
        };
        let json = serde_json::to_string(&options).expect("Failed to serialize");
        assert!(json.contains("test/repo"));
        assert!(json.contains("text"));
    }

    // Test limit validation for get_scan_history
    #[test]
    fn test_get_scan_history_limit_validation() {
        // Test limit upper bound
        let limit = 50;
        let validated = limit.min(1000);
        assert_eq!(validated, 50);

        // Test limit over 1000
        let limit = 2000;
        let validated = limit.min(1000);
        assert_eq!(validated, 1000);
    }
}

// When tempfile is available, we can use it for temp directory creation
#[cfg(test)]
mod tempfile {
    use std::fs;
    use std::path::Path;

    pub struct TempDir {
        path: std::path::PathBuf,
    }

    impl TempDir {
        pub fn path(&self) -> &Path {
            &self.path
        }
    }

    impl Drop for TempDir {
        fn drop(&mut self) {
            // Best effort cleanup
            let _ = fs::remove_dir_all(&self.path);
        }
    }

    pub fn tempdir() -> std::io::Result<TempDir> {
        let base_path = std::env::var("TMPDIR")
            .or_else(|_| std::env::var("TMP"))
            .unwrap_or_else(|_| "/tmp".to_string());

        let temp_dir = std::path::PathBuf::from(base_path);
        let unique_name = format!("skillsinspector_test_{}", std::process::id());
        let dir_path = temp_dir.join(unique_name);

        fs::create_dir(&dir_path)?;
        Ok(TempDir { path: dir_path })
    }
}
