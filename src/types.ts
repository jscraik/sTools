/**
 * Scan options passed to Tauri commands
 */
export interface ScanOptions {
  repo: string
  format: string
}

/**
 * Sync-check options passed to Tauri commands
 */
export interface SyncCheckOptions {
  repo: string
  format: string
}

/**
 * Result from a scan or sync-check command
 */
export interface ScanResult {
  success: boolean
  output: string
  exit_code: number
  error: string | null
}

/**
 * Finding from scan output
 */
export interface Finding {
  ruleID: string
  severity: "error" | "warning" | "info"
  agent: string
  file: string
  message: string
  line?: number
  column?: number
}

/**
 * Complete scan output (parsed JSON)
 */
export interface ScanOutput {
  schemaVersion: string
  toolVersion: string
  generatedAt: string
  scanned: number
  errors: number
  warnings: number
  findings: Finding[]
}
