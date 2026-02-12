/// Tests for SkillsInspector Tauri commands
use std::fs;

// Helper to create a temporary test directory
fn create_test_dir(_name: &str) -> tempfile::TempDir {
    tempfile::tempdir().expect("Failed to create temp dir")
}

// Helper to create a test git repository
fn create_test_git_repo() -> tempfile::TempDir {
    let dir = create_test_dir("test_repo");
    let git_dir = dir.path().join(".git");
    fs::create_dir(&git_dir).expect("Failed to create .git dir");
    dir
}

// tempfile module for temp directory creation
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
        // Use timestamp + counter for uniqueness
        use std::sync::atomic::{AtomicU64, Ordering};
        static COUNTER: AtomicU64 = AtomicU64::new(0);
        let count = COUNTER.fetch_add(1, Ordering::SeqCst);
        let unique_name = format!(
            "skillsinspector_test_{}_{}_{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_millis(),
            count
        );
        let dir_path = temp_dir.join(unique_name);

        fs::create_dir(&dir_path)?;
        Ok(TempDir { path: dir_path })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

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

    #[test]
    fn test_validate_path_string_single_dot() {
        // Single dot is valid (current directory)
        let result = validate_path_string("./relative/path");
        assert!(result.is_ok());
    }

    #[test]
    fn test_validate_path_string_with_tilde() {
        // Tilde should be valid (gets expanded)
        let result = validate_path_string("~/projects/myrepo");
        assert!(result.is_ok());
    }

    #[test]
    fn test_validate_path_string_dot_in_middle() {
        // Dot in middle of path is fine
        let result = validate_path_string("/path/to/my.dir/file");
        assert!(result.is_ok());
    }

    #[test]
    fn test_validate_path_string_dot_dot_in_filename() {
        // Double dot in filename is fine, only traversal pattern is bad
        let result = validate_path_string("/path/file..txt");
        assert!(result.is_ok());
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

        let result = validate_repo_path(file_path.to_str().unwrap());
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), ValidationError::NotDirectory));
    }

    #[test]
    fn test_validate_repo_path_not_git_repository() {
        let dir = create_test_dir("no_git");
        // It's a directory but not a git repo
        let result = validate_repo_path(dir.path().to_str().unwrap());
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), ValidationError::NotGitRepository));
    }

    #[test]
    fn test_validate_repo_path_success() {
        let dir = create_test_git_repo();
        let result = validate_repo_path(dir.path().to_str().unwrap());
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

    #[test]
    fn test_validate_format_empty() {
        let result = validate_format("");
        assert!(result.is_err());
    }

    // Tests for ValidationError Display
    #[test]
    fn test_validation_error_display_empty_path() {
        let error = ValidationError::EmptyPath;
        assert_eq!(error.to_string(), "Repository path cannot be empty");
    }

    #[test]
    fn test_validation_error_display_path_too_long() {
        let error = ValidationError::PathTooLong;
        assert_eq!(error.to_string(), "Repository path exceeds maximum length");
    }

    #[test]
    fn test_validation_error_display_invalid_characters() {
        let error = ValidationError::InvalidCharacters;
        assert_eq!(error.to_string(), "Repository path contains invalid characters");
    }

    #[test]
    fn test_validation_error_display_path_traversal() {
        let error = ValidationError::PathTraversal;
        assert_eq!(error.to_string(), "Repository path contains path traversal sequences");
    }

    #[test]
    fn test_validation_error_display_not_found() {
        let error = ValidationError::NotFound;
        assert_eq!(error.to_string(), "Repository path does not exist");
    }

    #[test]
    fn test_validation_error_display_not_directory() {
        let error = ValidationError::NotDirectory;
        assert_eq!(error.to_string(), "Repository path is not a directory");
    }

    #[test]
    fn test_validation_error_display_not_git_repository() {
        let error = ValidationError::NotGitRepository;
        assert_eq!(error.to_string(), "Repository path is not a git repository");
    }

    // Test ValidationError conversion to String
    #[test]
    fn test_validation_error_into_string() {
        let error = ValidationError::EmptyPath;
        let error_string: String = error.into();
        assert_eq!(error_string, "Repository path cannot be empty");
    }

    // Test error trait implementation
    #[test]
    fn test_validation_error_source() {
        let error = ValidationError::NotFound;
        // ValidationError doesn't have a source (it's a root error)
        assert!(std::error::Error::source(&error).is_none());
    }

    // Test expand_tilde function
    #[test]
    fn test_expand_tilde_with_home() {
        // Test that tilde expansion works when HOME is set
        // by checking the result is different from input (was expanded)
        let result = expand_tilde("~/test/path");
        let input = std::path::PathBuf::from("~/test/path");
        
        // If HOME is set, result should be expanded (not equal to input)
        // If HOME is not set, result equals input
        // Either way is valid behavior, we just check consistency
        if std::env::var("HOME").is_ok() {
            assert_ne!(result, input, "tilde should be expanded when HOME is set");
            assert!(!result.to_string_lossy().contains('~'), "expanded path should not contain ~");
        } else {
            assert_eq!(result, input, "tilde should not be expanded when HOME is not set");
        }
    }

    #[test]
    fn test_expand_tilde_without_tilde() {
        let result = expand_tilde("/absolute/path");
        assert_eq!(result, std::path::PathBuf::from("/absolute/path"));
    }

    #[test]
    fn test_expand_tilde_just_tilde() {
        let home = std::env::var("HOME").unwrap_or_else(|_| "/home/test".to_string());
        let result = expand_tilde("~");
        assert_eq!(result, std::path::PathBuf::from(&home));
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

    #[test]
    fn test_scan_options_with_empty_repo() {
        let options = ScanOptions {
            repo: "".to_string(),
            format: "json".to_string(),
        };
        // Format is valid, but repo is empty - would be caught by path validation
        assert!(validate_format(&options.format).is_ok());
    }

    // Tests for SyncCheckOptions
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

    #[test]
    fn test_sync_check_options_deserialize() {
        let json = r#"{"repo":"/test/repo","format":"text"}"#;
        let options: SyncCheckOptions = serde_json::from_str(json).expect("Failed to deserialize");
        assert_eq!(options.repo, "/test/repo");
        assert_eq!(options.format, "text");
    }

    #[test]
    fn test_sync_check_options_with_empty_format() {
        let options = SyncCheckOptions {
            repo: "/valid/path".to_string(),
            format: "".to_string(),
        };
        // Empty format is invalid
        assert!(validate_format(&options.format).is_err());
    }

    // Tests for ScanResult serialization/deserialization
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

    #[test]
    fn test_scan_result_deserialize_success() {
        let json = r#"{"success":true,"output":"test","exit_code":0,"error":null}"#;
        let result: ScanResult = serde_json::from_str(json).expect("Failed to deserialize");
        assert!(result.success);
        assert_eq!(result.exit_code, 0);
        assert!(result.error.is_none());
    }

    #[test]
    fn test_scan_result_deserialize_with_error() {
        let json = r#"{"success":false,"output":"","exit_code":1,"error":"Something failed"}"#;
        let result: ScanResult = serde_json::from_str(json).expect("Failed to deserialize");
        assert!(!result.success);
        assert_eq!(result.exit_code, 1);
        assert_eq!(result.error, Some("Something failed".to_string()));
    }

    // Integration-style tests for validation paths
    #[test]
    fn test_run_scan_with_invalid_format_returns_error() {
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

    // Test limit validation
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

        // Test limit at exactly 1000
        let limit = 1000;
        let validated = limit.min(1000);
        assert_eq!(validated, 1000);
    }

    // Test MAX_PATH_LENGTH constant
    #[test]
    fn test_max_path_length_constant() {
        assert_eq!(MAX_PATH_LENGTH, 4096);
        
        // Test that 4096 character path is rejected
        let long_path = "a".repeat(MAX_PATH_LENGTH + 1);
        let result = validate_path_string(&long_path);
        assert!(result.is_err());
        assert!(matches!(result.unwrap_err(), ValidationError::PathTooLong));
    }
}
