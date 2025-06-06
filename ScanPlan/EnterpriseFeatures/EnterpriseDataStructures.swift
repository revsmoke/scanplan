import Foundation
import CryptoKit

// MARK: - Integration Status

/// Integration status
enum IntegrationStatus: String, CaseIterable, Codable {
    case disconnected = "disconnected"
    case connecting = "connecting"
    case connected = "connected"
    case configuring = "configuring"
    case active = "active"
    case failed = "failed"
    case suspended = "suspended"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .disconnected: return "wifi.slash"
        case .connecting: return "wifi.exclamationmark"
        case .connected: return "wifi"
        case .configuring: return "gearshape"
        case .active: return "checkmark.circle"
        case .failed: return "xmark.circle"
        case .suspended: return "pause.circle"
        }
    }
}

// MARK: - Enterprise Integration

/// Enterprise integration
struct EnterpriseIntegration: Identifiable, Codable {
    let id: UUID
    let type: IntegrationType
    let name: String
    let description: String
    var status: IntegrationStatus
    let createdDate: Date
    var lastActivity: Date?
    let config: APIIntegrationConfig
    
    var isActive: Bool {
        return status == .active
    }
    
    var displayStatus: String {
        return status.displayName
    }
}

/// Integration types
enum IntegrationType: String, CaseIterable, Codable {
    case restAPI = "rest_api"
    case graphQL = "graphql"
    case webhook = "webhook"
    case database = "database"
    case fileSystem = "file_system"
    case cloudStorage = "cloud_storage"
    case messaging = "messaging"
    case analytics = "analytics"
    case crm = "crm"
    case erp = "erp"
    case cad = "cad"
    case bim = "bim"
    
    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    var icon: String {
        switch self {
        case .restAPI: return "network"
        case .graphQL: return "arrow.triangle.branch"
        case .webhook: return "link"
        case .database: return "cylinder"
        case .fileSystem: return "folder"
        case .cloudStorage: return "icloud"
        case .messaging: return "message"
        case .analytics: return "chart.bar"
        case .crm: return "person.2"
        case .erp: return "building.2"
        case .cad: return "cube.transparent"
        case .bim: return "house"
        }
    }
}

// MARK: - API Integration

/// API integration configuration
struct APIIntegrationConfig: Codable {
    let name: String
    let description: String
    let baseURL: String
    let authentication: AuthenticationConfig
    let endpoints: [APIEndpoint]
    let rateLimit: RateLimit
    let timeout: TimeInterval
    let retryPolicy: RetryPolicy
    let enableLogging: Bool
    let enableCaching: Bool
    
    var isValid: Bool {
        return !baseURL.isEmpty && !endpoints.isEmpty
    }
}

/// Authentication configuration
struct AuthenticationConfig: Codable {
    let type: AuthenticationType
    let credentials: [String: String]
    let tokenEndpoint: String?
    let refreshEndpoint: String?
    let scopes: [String]
    
    enum AuthenticationType: String, CaseIterable, Codable {
        case none = "none"
        case apiKey = "api_key"
        case bearer = "bearer"
        case oauth2 = "oauth2"
        case basic = "basic"
        case custom = "custom"
        
        var displayName: String {
            return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

/// API endpoint
struct APIEndpoint: Codable {
    let path: String
    let method: HTTPMethod
    let description: String
    let parameters: [APIParameter]
    let headers: [String: String]
    let responseFormat: ResponseFormat
    
    var url: String {
        return path
    }
    
    var isValid: Bool {
        return !path.isEmpty
    }
    
    enum HTTPMethod: String, CaseIterable, Codable {
        case GET = "GET"
        case POST = "POST"
        case PUT = "PUT"
        case DELETE = "DELETE"
        case PATCH = "PATCH"
        case HEAD = "HEAD"
        case OPTIONS = "OPTIONS"
    }
    
    enum ResponseFormat: String, CaseIterable, Codable {
        case json = "json"
        case xml = "xml"
        case csv = "csv"
        case binary = "binary"
        case text = "text"
    }
}

/// API parameter
struct APIParameter: Codable {
    let name: String
    let type: ParameterType
    let required: Bool
    let description: String
    let defaultValue: String?
    
    enum ParameterType: String, CaseIterable, Codable {
        case string = "string"
        case integer = "integer"
        case float = "float"
        case boolean = "boolean"
        case array = "array"
        case object = "object"
    }
}

/// Rate limit configuration
struct RateLimit: Codable {
    let requestsPerMinute: Int
    let requestsPerHour: Int
    let requestsPerDay: Int
    let enableThrottling: Bool
    
    static func `default`() -> RateLimit {
        return RateLimit(
            requestsPerMinute: 60,
            requestsPerHour: 1000,
            requestsPerDay: 10000,
            enableThrottling: true
        )
    }
}

/// Retry policy
struct RetryPolicy: Codable {
    let maxRetries: Int
    let backoffStrategy: BackoffStrategy
    let retryableStatusCodes: [Int]
    
    enum BackoffStrategy: String, CaseIterable, Codable {
        case linear = "linear"
        case exponential = "exponential"
        case fixed = "fixed"
        
        var displayName: String {
            return rawValue.capitalized
        }
    }
    
    static func `default`() -> RetryPolicy {
        return RetryPolicy(
            maxRetries: 3,
            backoffStrategy: .exponential,
            retryableStatusCodes: [429, 500, 502, 503, 504]
        )
    }
}

// MARK: - API Connection

/// API connection
struct APIConnection: Identifiable, Codable {
    let id: UUID
    let type: IntegrationType
    let config: APIIntegrationConfig
    let status: ConnectionStatus
    let createdDate: Date
    var lastUsed: Date?
    var metrics: ConnectionMetrics
    
    enum ConnectionStatus: String, CaseIterable, Codable {
        case inactive = "inactive"
        case active = "active"
        case error = "error"
        case testing = "testing"
        
        var displayName: String {
            return rawValue.capitalized
        }
    }
    
    func testConnection() async throws -> ConnectionTestResponse {
        // Simplified connection test
        return ConnectionTestResponse(
            isSuccessful: true,
            responseTime: 0.1,
            error: nil
        )
    }
}

/// Connection test response
struct ConnectionTestResponse: Codable {
    let isSuccessful: Bool
    let responseTime: TimeInterval
    let error: String?
}

/// Connection test result
struct ConnectionTestResult: Codable {
    let isSuccessful: Bool
    let responseTime: TimeInterval
    let error: String?
}

/// Connection metrics
struct ConnectionMetrics: Codable {
    var totalRequests: Int = 0
    var successfulRequests: Int = 0
    var failedRequests: Int = 0
    var averageResponseTime: TimeInterval = 0.0
    var lastRequestTime: Date?
    
    var successRate: Float {
        guard totalRequests > 0 else { return 0.0 }
        return Float(successfulRequests) / Float(totalRequests)
    }
}

// MARK: - Security

/// Security status
struct SecurityStatus: Codable {
    var securityLevel: SecurityLevel = .standard
    var encryptionEnabled: Bool = false
    var accessControlsEnabled: Bool = false
    var ssoEnabled: Bool = false
    var auditLoggingEnabled: Bool = false
    var lastSecurityUpdate: Date?
    var lastSecurityAudit: Date?
    var lastSecurityCheck: Date?
    var securityScore: Float = 0.0
    var threatLevel: ThreatLevel = .low
}

/// Security levels
enum SecurityLevel: String, CaseIterable, Codable {
    case none = "none"
    case basic = "basic"
    case standard = "standard"
    case enhanced = "enhanced"
    case enterprise = "enterprise"
    case maximum = "maximum"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var securityScore: Float {
        switch self {
        case .none: return 0.0
        case .basic: return 0.2
        case .standard: return 0.5
        case .enhanced: return 0.7
        case .enterprise: return 0.9
        case .maximum: return 1.0
        }
    }
}

/// Threat levels
enum ThreatLevel: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

/// Enterprise security settings
struct EnterpriseSecuritySettings: Codable {
    let securityLevel: SecurityLevel
    let enableAdvancedEncryption: Bool
    let enableAccessControls: Bool
    let enableAuditLogging: Bool
    let encryptionConfig: EncryptionConfig
    let accessControls: AccessControlConfig
    let auditConfig: AuditConfig
    
    static func `default`() -> EnterpriseSecuritySettings {
        return EnterpriseSecuritySettings(
            securityLevel: .enterprise,
            enableAdvancedEncryption: true,
            enableAccessControls: true,
            enableAuditLogging: true,
            encryptionConfig: EncryptionConfig.default(),
            accessControls: AccessControlConfig.default(),
            auditConfig: AuditConfig.default()
        )
    }
}

/// Encryption configuration
struct EncryptionConfig: Codable {
    let algorithm: EncryptionAlgorithm
    let keySize: Int
    let enableDataAtRest: Bool
    let enableDataInTransit: Bool
    let enableEndToEnd: Bool
    
    enum EncryptionAlgorithm: String, CaseIterable, Codable {
        case aes256 = "aes256"
        case chacha20 = "chacha20"
        case rsa2048 = "rsa2048"
        case rsa4096 = "rsa4096"
        
        var displayName: String {
            return rawValue.uppercased()
        }
    }
    
    static func `default`() -> EncryptionConfig {
        return EncryptionConfig(
            algorithm: .aes256,
            keySize: 256,
            enableDataAtRest: true,
            enableDataInTransit: true,
            enableEndToEnd: true
        )
    }
}

/// Access control configuration
struct AccessControlConfig: Codable {
    let enableRoleBasedAccess: Bool
    let enableMultiFactorAuth: Bool
    let enableSessionTimeout: Bool
    let sessionTimeoutMinutes: Int
    let enableIPWhitelist: Bool
    let allowedIPs: [String]
    
    static func `default`() -> AccessControlConfig {
        return AccessControlConfig(
            enableRoleBasedAccess: true,
            enableMultiFactorAuth: true,
            enableSessionTimeout: true,
            sessionTimeoutMinutes: 60,
            enableIPWhitelist: false,
            allowedIPs: []
        )
    }
}

/// Audit configuration
struct AuditConfig: Codable {
    let enableUserActions: Bool
    let enableSystemEvents: Bool
    let enableDataAccess: Bool
    let enableConfigChanges: Bool
    let retentionDays: Int
    let enableRealTimeAlerts: Bool
    
    static func `default`() -> AuditConfig {
        return AuditConfig(
            enableUserActions: true,
            enableSystemEvents: true,
            enableDataAccess: true,
            enableConfigChanges: true,
            retentionDays: 365,
            enableRealTimeAlerts: true
        )
    }
}

/// Security event
struct SecurityEvent: Identifiable, Codable {
    let id: UUID
    let type: SecurityEventType
    let severity: SecuritySeverity
    let description: String
    let source: String
    let timestamp: Date
    let userId: UUID?
    let ipAddress: String?
    let userAgent: String?
    
    enum SecurityEventType: String, CaseIterable, Codable {
        case login = "login"
        case logout = "logout"
        case failedLogin = "failed_login"
        case dataAccess = "data_access"
        case configChange = "config_change"
        case apiAccess = "api_access"
        case suspiciousActivity = "suspicious_activity"
        
        var displayName: String {
            return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
    
    enum SecuritySeverity: String, CaseIterable, Codable {
        case info = "info"
        case warning = "warning"
        case error = "error"
        case critical = "critical"
        
        var displayName: String {
            return rawValue.capitalized
        }
    }
}

// MARK: - Compliance

/// Compliance status
struct ComplianceStatus: Codable {
    var enabledStandards: [ComplianceStandard] = []
    var complianceScore: Float = 0.0
    var lastAssessment: Date?
    var lastComplianceCheck: Date?
    var issues: [ComplianceIssue] = []
    var certifications: [ComplianceCertification] = []
}

/// Compliance standards
enum ComplianceStandard: String, CaseIterable, Codable {
    case iso27001 = "iso27001"
    case gdpr = "gdpr"
    case hipaa = "hipaa"
    case sox = "sox"
    case pci = "pci"
    case fisma = "fisma"
    case nist = "nist"
    case ccpa = "ccpa"
    
    var displayName: String {
        return rawValue.uppercased()
    }
    
    var description: String {
        switch self {
        case .iso27001: return "ISO/IEC 27001 Information Security Management"
        case .gdpr: return "General Data Protection Regulation"
        case .hipaa: return "Health Insurance Portability and Accountability Act"
        case .sox: return "Sarbanes-Oxley Act"
        case .pci: return "Payment Card Industry Data Security Standard"
        case .fisma: return "Federal Information Security Management Act"
        case .nist: return "National Institute of Standards and Technology"
        case .ccpa: return "California Consumer Privacy Act"
        }
    }
}

/// Compliance issue
struct ComplianceIssue: Identifiable, Codable {
    let id: UUID
    let standard: ComplianceStandard
    let severity: ComplianceSeverity
    let description: String
    let requirement: String
    let remediation: String
    let dueDate: Date?
    let status: ComplianceIssueStatus
    let timestamp: Date
    
    enum ComplianceSeverity: String, CaseIterable, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
        
        var displayName: String {
            return rawValue.capitalized
        }
    }
    
    enum ComplianceIssueStatus: String, CaseIterable, Codable {
        case open = "open"
        case inProgress = "in_progress"
        case resolved = "resolved"
        case deferred = "deferred"
        
        var displayName: String {
            return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

/// Compliance certification
struct ComplianceCertification: Identifiable, Codable {
    let id: UUID
    let standard: ComplianceStandard
    let certificationBody: String
    let issueDate: Date
    let expiryDate: Date
    let certificateNumber: String
    let status: CertificationStatus
    
    enum CertificationStatus: String, CaseIterable, Codable {
        case valid = "valid"
        case expiring = "expiring"
        case expired = "expired"
        case suspended = "suspended"
        
        var displayName: String {
            return rawValue.capitalized
        }
    }
    
    var isValid: Bool {
        return status == .valid && expiryDate > Date()
    }
    
    var daysUntilExpiry: Int {
        return Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
    }
}
