import Foundation
import CloudKit

// MARK: - Cloud User Management

/// Cloud user representation
struct CloudUser: Identifiable, Codable {
    let id: UUID
    let email: String
    let displayName: String
    let avatar: String?
    let role: UserRole
    let permissions: UserPermissions
    let lastActive: Date
    let isOnline: Bool
    let preferences: UserPreferences
    
    var initials: String {
        let components = displayName.components(separatedBy: " ")
        return components.compactMap { $0.first }.map { String($0) }.joined()
    }
}

/// User roles in the system
enum UserRole: String, CaseIterable, Codable {
    case owner = "owner"
    case admin = "admin"
    case editor = "editor"
    case viewer = "viewer"
    case guest = "guest"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var canEdit: Bool {
        switch self {
        case .owner, .admin, .editor: return true
        case .viewer, .guest: return false
        }
    }
    
    var canShare: Bool {
        switch self {
        case .owner, .admin: return true
        case .editor, .viewer, .guest: return false
        }
    }
    
    var canDelete: Bool {
        switch self {
        case .owner, .admin: return true
        case .editor, .viewer, .guest: return false
        }
    }
}

/// User permissions structure
struct UserPermissions: Codable {
    let canRead: Bool
    let canWrite: Bool
    let canDelete: Bool
    let canShare: Bool
    let canExport: Bool
    let canMeasure: Bool
    let canAnalyze: Bool
    let canCollaborate: Bool
    
    static func `default`(for role: UserRole) -> UserPermissions {
        switch role {
        case .owner:
            return UserPermissions(canRead: true, canWrite: true, canDelete: true, canShare: true, canExport: true, canMeasure: true, canAnalyze: true, canCollaborate: true)
        case .admin:
            return UserPermissions(canRead: true, canWrite: true, canDelete: true, canShare: true, canExport: true, canMeasure: true, canAnalyze: true, canCollaborate: true)
        case .editor:
            return UserPermissions(canRead: true, canWrite: true, canDelete: false, canShare: false, canExport: true, canMeasure: true, canAnalyze: true, canCollaborate: true)
        case .viewer:
            return UserPermissions(canRead: true, canWrite: false, canDelete: false, canShare: false, canExport: true, canMeasure: false, canAnalyze: false, canCollaborate: true)
        case .guest:
            return UserPermissions(canRead: true, canWrite: false, canDelete: false, canShare: false, canExport: false, canMeasure: false, canAnalyze: false, canCollaborate: false)
        }
    }
}

/// User preferences
struct UserPreferences: Codable {
    let theme: String
    let language: String
    let timezone: String
    let notifications: NotificationPreferences
    let collaboration: CollaborationPreferences
    
    static func `default`() -> UserPreferences {
        return UserPreferences(
            theme: "professional",
            language: "en",
            timezone: "UTC",
            notifications: NotificationPreferences.default(),
            collaboration: CollaborationPreferences.default()
        )
    }
}

/// Notification preferences
struct NotificationPreferences: Codable {
    let enablePushNotifications: Bool
    let enableEmailNotifications: Bool
    let enableCollaborationNotifications: Bool
    let enableSyncNotifications: Bool
    let enableMentionNotifications: Bool
    
    static func `default`() -> NotificationPreferences {
        return NotificationPreferences(
            enablePushNotifications: true,
            enableEmailNotifications: true,
            enableCollaborationNotifications: true,
            enableSyncNotifications: false,
            enableMentionNotifications: true
        )
    }
}

/// Collaboration preferences
struct CollaborationPreferences: Codable {
    let enableRealTimeEditing: Bool
    let enablePresenceIndicators: Bool
    let enableVoiceChat: Bool
    let enableScreenSharing: Bool
    let autoJoinSessions: Bool
    
    static func `default`() -> CollaborationPreferences {
        return CollaborationPreferences(
            enableRealTimeEditing: true,
            enablePresenceIndicators: true,
            enableVoiceChat: false,
            enableScreenSharing: false,
            autoJoinSessions: false
        )
    }
}

// MARK: - Team Management

/// Team member representation
struct TeamMember: Identifiable, Codable {
    let id: UUID
    let user: CloudUser
    let joinDate: Date
    let role: UserRole
    let permissions: UserPermissions
    let isActive: Bool
    let lastContribution: Date?
    
    var displayName: String {
        return user.displayName
    }
    
    var isOnline: Bool {
        return user.isOnline
    }
}

/// Team structure
struct Team: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String?
    let owner: CloudUser
    let members: [TeamMember]
    let createdDate: Date
    let lastActivity: Date
    let settings: TeamSettings
    
    var memberCount: Int {
        return members.count
    }
    
    var onlineMembers: [TeamMember] {
        return members.filter { $0.isOnline }
    }
}

/// Team settings
struct TeamSettings: Codable {
    let isPublic: Bool
    let allowGuestAccess: Bool
    let requireApprovalForJoining: Bool
    let enableRealTimeCollaboration: Bool
    let maxMembers: Int
    let defaultMemberRole: UserRole
    
    static func `default`() -> TeamSettings {
        return TeamSettings(
            isPublic: false,
            allowGuestAccess: false,
            requireApprovalForJoining: true,
            enableRealTimeCollaboration: true,
            maxMembers: 50,
            defaultMemberRole: .viewer
        )
    }
}

// MARK: - Cloud Projects

/// Cloud project representation
struct CloudProject: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String?
    let owner: CloudUser
    let team: Team?
    let createdDate: Date
    let lastModified: Date
    let version: ProjectVersion
    let status: ProjectStatus
    let settings: ProjectSettings
    let metadata: ProjectMetadata
    
    var isShared: Bool {
        return team != nil
    }
    
    var collaboratorCount: Int {
        return team?.memberCount ?? 1
    }
}

/// Project version information
struct ProjectVersion: Codable {
    let major: Int
    let minor: Int
    let patch: Int
    let build: Int
    let tag: String?
    
    var versionString: String {
        var version = "\(major).\(minor).\(patch)"
        if build > 0 {
            version += ".\(build)"
        }
        if let tag = tag {
            version += "-\(tag)"
        }
        return version
    }
    
    static func initial() -> ProjectVersion {
        return ProjectVersion(major: 1, minor: 0, patch: 0, build: 0, tag: nil)
    }
}

/// Project status
enum ProjectStatus: String, CaseIterable, Codable {
    case active = "active"
    case archived = "archived"
    case shared = "shared"
    case syncing = "syncing"
    case offline = "offline"
    case conflicted = "conflicted"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .active: return "circle.fill"
        case .archived: return "archivebox"
        case .shared: return "person.2"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .offline: return "wifi.slash"
        case .conflicted: return "exclamationmark.triangle"
        }
    }
}

/// Project settings
struct ProjectSettings: Codable {
    let isPublic: Bool
    let allowCollaboration: Bool
    let enableVersionControl: Bool
    let enableRealTimeSync: Bool
    let enableOfflineMode: Bool
    let compressionEnabled: Bool
    let encryptionEnabled: Bool
    let backupEnabled: Bool
    
    static func `default`() -> ProjectSettings {
        return ProjectSettings(
            isPublic: false,
            allowCollaboration: true,
            enableVersionControl: true,
            enableRealTimeSync: true,
            enableOfflineMode: true,
            compressionEnabled: true,
            encryptionEnabled: true,
            backupEnabled: true
        )
    }
}

// MARK: - Real-Time Communication

/// Collaboration message
struct CollaborationMessage: Identifiable, Codable {
    let id: UUID
    let sender: CloudUser
    let content: MessageContent
    let timestamp: Date
    let sessionId: UUID
    let replyTo: UUID?
    let mentions: [UUID] // User IDs
    let reactions: [MessageReaction]

    var isReply: Bool {
        return replyTo != nil
    }

    var hasMentions: Bool {
        return !mentions.isEmpty
    }
}

/// Message content types
enum MessageContent: Codable {
    case text(String)
    case measurement(UUID) // Measurement ID
    case analysis(UUID) // Analysis ID
    case file(FileAttachment)
    case location(LocationPin)
    case system(SystemMessage)

    var displayText: String {
        switch self {
        case .text(let text):
            return text
        case .measurement:
            return "📏 Shared a measurement"
        case .analysis:
            return "📊 Shared an analysis"
        case .file(let file):
            return "📎 Shared \(file.name)"
        case .location:
            return "📍 Shared a location"
        case .system(let message):
            return message.text
        }
    }
}

/// File attachment
struct FileAttachment: Codable {
    let id: UUID
    let name: String
    let type: String
    let size: Int64
    let url: String
    let thumbnail: String?
}

/// Location pin
struct LocationPin: Codable {
    let id: UUID
    let name: String
    let coordinates: SIMD3<Float>
    let description: String?
}

/// System message
struct SystemMessage: Codable {
    let type: SystemMessageType
    let text: String
    let data: [String: String]?
}

/// System message types
enum SystemMessageType: String, CaseIterable, Codable {
    case userJoined = "user_joined"
    case userLeft = "user_left"
    case sessionStarted = "session_started"
    case sessionEnded = "session_ended"
    case projectShared = "project_shared"
    case measurementAdded = "measurement_added"
    case analysisCompleted = "analysis_completed"

    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

/// Message reaction
struct MessageReaction: Codable {
    let emoji: String
    let users: [UUID] // User IDs who reacted
    let timestamp: Date
}

/// Collaboration activity
struct CollaborationActivity: Identifiable, Codable {
    let id: UUID
    let user: CloudUser
    let type: ActivityType
    let description: String
    let timestamp: Date
    let data: ActivityData?
}

/// Activity types
enum ActivityType: String, CaseIterable, Codable {
    case joined = "joined"
    case left = "left"
    case edited = "edited"
    case measured = "measured"
    case analyzed = "analyzed"
    case exported = "exported"
    case shared = "shared"
    case commented = "commented"

    var displayName: String {
        return rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .joined: return "person.badge.plus"
        case .left: return "person.badge.minus"
        case .edited: return "pencil"
        case .measured: return "ruler"
        case .analyzed: return "chart.bar"
        case .exported: return "square.and.arrow.up"
        case .shared: return "square.and.arrow.up"
        case .commented: return "bubble.left"
        }
    }
}

/// Activity data
struct ActivityData: Codable {
    let objectId: UUID?
    let objectType: String?
    let details: [String: String]?
}

// MARK: - Presence and Cursor

/// Presence information
struct PresenceInfo: Identifiable, Codable {
    let id: UUID
    let user: CloudUser
    let status: PresenceStatus
    let lastSeen: Date
    let currentActivity: String?
    let cursor: CursorPosition?
}

/// Presence status
enum PresenceStatus: String, CaseIterable, Codable {
    case online = "online"
    case away = "away"
    case busy = "busy"
    case offline = "offline"

    var displayName: String {
        return rawValue.capitalized
    }

    var color: String {
        switch self {
        case .online: return "green"
        case .away: return "yellow"
        case .busy: return "red"
        case .offline: return "gray"
        }
    }
}

/// Cursor position for real-time collaboration
struct CursorPosition: Codable {
    let x: Float
    let y: Float
    let z: Float?
    let viewId: String?
    let timestamp: Date

    init(x: Float, y: Float, z: Float? = nil, viewId: String? = nil) {
        self.x = x
        self.y = y
        self.z = z
        self.viewId = viewId
        self.timestamp = Date()
    }
}

// MARK: - Synchronization

/// Sync status
enum SyncStatus: String, CaseIterable, Codable {
    case idle = "idle"
    case syncing = "syncing"
    case completed = "completed"
    case failed = "failed"
    case offline = "offline"
    case conflicted = "conflicted"

    var displayName: String {
        return rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .idle: return "circle"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle"
        case .failed: return "xmark.circle"
        case .offline: return "wifi.slash"
        case .conflicted: return "exclamationmark.triangle"
        }
    }
}

/// Sync progress
struct SyncProgress: Codable {
    var totalItems: Int = 0
    var completedItems: Int = 0
    var currentItem: String?
    var estimatedTimeRemaining: TimeInterval?
    var bytesTransferred: Int64 = 0
    var totalBytes: Int64 = 0

    var percentage: Float {
        guard totalItems > 0 else { return 0.0 }
        return Float(completedItems) / Float(totalItems)
    }

    var isComplete: Bool {
        return completedItems >= totalItems && totalItems > 0
    }
}

/// Sync task
struct SyncTask: Identifiable, Codable {
    let id: UUID
    let type: SyncTaskType
    let projectId: UUID
    let startTime: Date
    var endTime: Date?
    var progress: Float = 0.0
    var status: SyncStatus = .idle
    var error: String?

    var duration: TimeInterval {
        return (endTime ?? Date()).timeIntervalSince(startTime)
    }

    var isComplete: Bool {
        return endTime != nil
    }
}

/// Sync task types
enum SyncTaskType: String, CaseIterable, Codable {
    case upload = "upload"
    case download = "download"
    case update = "update"
    case delete = "delete"
    case merge = "merge"

    var displayName: String {
        return rawValue.capitalized
    }
}

/// Sync result
enum SyncResult {
    case success(data: SyncResultData)
    case failure(error: SyncError)

    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
}

/// Sync result data
struct SyncResultData: Codable {
    let taskId: UUID
    let bytesTransferred: Int64
    let duration: TimeInterval
    let timestamp: Date
}

/// Sync errors
enum SyncError: Error, LocalizedError {
    case notConnected
    case authenticationFailed
    case networkError(Error)
    case syncFailed(Error)
    case conflictDetected
    case insufficientStorage
    case rateLimitExceeded

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to cloud"
        case .authenticationFailed:
            return "Authentication failed"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .syncFailed(let error):
            return "Sync failed: \(error.localizedDescription)"
        case .conflictDetected:
            return "Conflict detected during sync"
        case .insufficientStorage:
            return "Insufficient cloud storage"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        }
    }
}

// MARK: - Storage and Backup

/// Storage usage information
struct StorageUsage: Codable {
    let totalStorage: Int64
    let usedStorage: Int64
    let availableStorage: Int64
    let projectCount: Int
    let fileCount: Int
    let lastUpdated: Date

    var usagePercentage: Float {
        guard totalStorage > 0 else { return 0.0 }
        return Float(usedStorage) / Float(totalStorage)
    }

    var isNearLimit: Bool {
        return usagePercentage > 0.8
    }
}

/// Backup result
struct BackupResult: Codable {
    let backupId: UUID
    let projectId: UUID
    let size: Int64
    let timestamp: Date
    let isSuccessful: Bool
    let error: String?
}

/// Restore result
struct RestoreResult: Codable {
    let projectId: UUID
    let backupId: UUID
    let timestamp: Date
    let isSuccessful: Bool
    let error: String?
}

// MARK: - Analytics and Metrics

/// Cloud metrics
struct CloudMetrics: Codable {
    var totalSyncOperations: Int = 0
    var successfulSyncs: Int = 0
    var failedSyncs: Int = 0
    var averageSyncTime: TimeInterval = 0.0
    var syncSuccessRate: Float = 0.0
    var lastSyncTime: Date?
    var activeSessions: Int = 0
    var activeTeamMembers: Int = 0
    var totalProjects: Int = 0
    var lastUpdate: Date = Date()

    var efficiency: Float {
        guard totalSyncOperations > 0 else { return 0.0 }
        return syncSuccessRate
    }
}

/// Collaboration analytics
struct CollaborationAnalytics: Codable {
    let activeSessions: Int
    let totalTeamMembers: Int
    let totalProjects: Int
    let syncMetrics: CloudMetrics
    let averageSessionDuration: TimeInterval
    let totalMessages: Int
    let totalActivities: Int

    init(activeSessions: Int, totalTeamMembers: Int, totalProjects: Int, syncMetrics: CloudMetrics) {
        self.activeSessions = activeSessions
        self.totalTeamMembers = totalTeamMembers
        self.totalProjects = totalProjects
        self.syncMetrics = syncMetrics
        self.averageSessionDuration = 0.0 // Will be calculated
        self.totalMessages = 0 // Will be calculated
        self.totalActivities = 0 // Will be calculated
    }
}

/// Project metadata
struct ProjectMetadata: Codable {
    let fileSize: Int64
    let scanCount: Int
    let measurementCount: Int
    let analysisCount: Int
    let exportCount: Int
    let collaborationCount: Int
    let tags: [String]
    let categories: [String]
    
    static func empty() -> ProjectMetadata {
        return ProjectMetadata(
            fileSize: 0,
            scanCount: 0,
            measurementCount: 0,
            analysisCount: 0,
            exportCount: 0,
            collaborationCount: 0,
            tags: [],
            categories: []
        )
    }
}

/// Project permissions
struct ProjectPermissions: Codable {
    let read: [UUID] // User IDs
    let write: [UUID]
    let delete: [UUID]
    let share: [UUID]
    let export: [UUID]
    
    static func ownerOnly(_ ownerId: UUID) -> ProjectPermissions {
        return ProjectPermissions(
            read: [ownerId],
            write: [ownerId],
            delete: [ownerId],
            share: [ownerId],
            export: [ownerId]
        )
    }
}

// MARK: - Collaboration Sessions

/// Collaboration session
class CollaborationSession: Identifiable, Codable {
    let id: UUID
    let projectId: UUID
    let type: CollaborationSessionType
    let creator: CloudUser
    let startTime: Date
    var endTime: Date?
    var participants: [SessionParticipant] = []
    var messages: [CollaborationMessage] = []
    var activities: [CollaborationActivity] = []
    var settings: SessionSettings
    
    var isActive: Bool {
        return endTime == nil
    }
    
    var duration: TimeInterval {
        return (endTime ?? Date()).timeIntervalSince(startTime)
    }
    
    var participantCount: Int {
        return participants.count
    }
    
    init(id: UUID, projectId: UUID, type: CollaborationSessionType, creator: CloudUser, startTime: Date) {
        self.id = id
        self.projectId = projectId
        self.type = type
        self.creator = creator
        self.startTime = startTime
        self.settings = SessionSettings.default()
    }
    
    enum CodingKeys: String, CodingKey {
        case id, projectId, type, creator, startTime, endTime, participants, messages, activities, settings
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        projectId = try container.decode(UUID.self, forKey: .projectId)
        type = try container.decode(CollaborationSessionType.self, forKey: .type)
        creator = try container.decode(CloudUser.self, forKey: .creator)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        participants = try container.decode([SessionParticipant].self, forKey: .participants)
        messages = try container.decode([CollaborationMessage].self, forKey: .messages)
        activities = try container.decode([CollaborationActivity].self, forKey: .activities)
        settings = try container.decode(SessionSettings.self, forKey: .settings)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(projectId, forKey: .projectId)
        try container.encode(type, forKey: .type)
        try container.encode(creator, forKey: .creator)
        try container.encode(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encode(participants, forKey: .participants)
        try container.encode(messages, forKey: .messages)
        try container.encode(activities, forKey: .activities)
        try container.encode(settings, forKey: .settings)
    }
}

/// Collaboration session types
enum CollaborationSessionType: String, CaseIterable, Codable {
    case realTimeEditing = "real_time_editing"
    case reviewSession = "review_session"
    case measurementSession = "measurement_session"
    case analysisSession = "analysis_session"
    case presentationSession = "presentation_session"
    case trainingSession = "training_session"
    
    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    var icon: String {
        switch self {
        case .realTimeEditing: return "pencil.and.outline"
        case .reviewSession: return "eye"
        case .measurementSession: return "ruler"
        case .analysisSession: return "chart.bar.xaxis"
        case .presentationSession: return "presentation"
        case .trainingSession: return "graduationcap"
        }
    }
}

/// Session participant
struct SessionParticipant: Identifiable, Codable {
    let id: UUID
    let user: CloudUser
    let joinTime: Date
    var leaveTime: Date?
    let role: ParticipantRole
    let permissions: ParticipantPermissions
    var isPresent: Bool
    var cursor: CursorPosition?
    
    var sessionDuration: TimeInterval {
        return (leaveTime ?? Date()).timeIntervalSince(joinTime)
    }
}

/// Participant role in session
enum ParticipantRole: String, CaseIterable, Codable {
    case host = "host"
    case presenter = "presenter"
    case editor = "editor"
    case viewer = "viewer"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

/// Participant permissions in session
struct ParticipantPermissions: Codable {
    let canEdit: Bool
    let canMeasure: Bool
    let canAnalyze: Bool
    let canExport: Bool
    let canInvite: Bool
    let canKick: Bool
    let canMute: Bool
    
    static func `default`(for role: ParticipantRole) -> ParticipantPermissions {
        switch role {
        case .host:
            return ParticipantPermissions(canEdit: true, canMeasure: true, canAnalyze: true, canExport: true, canInvite: true, canKick: true, canMute: true)
        case .presenter:
            return ParticipantPermissions(canEdit: true, canMeasure: true, canAnalyze: true, canExport: true, canInvite: false, canKick: false, canMute: false)
        case .editor:
            return ParticipantPermissions(canEdit: true, canMeasure: true, canAnalyze: true, canExport: false, canInvite: false, canKick: false, canMute: false)
        case .viewer:
            return ParticipantPermissions(canEdit: false, canMeasure: false, canAnalyze: false, canExport: false, canInvite: false, canKick: false, canMute: false)
        }
    }
}

/// Session settings
struct SessionSettings: Codable {
    let enableVoiceChat: Bool
    let enableScreenSharing: Bool
    let enableRealTimeEditing: Bool
    let enablePresenceIndicators: Bool
    let maxParticipants: Int
    let requireApproval: Bool
    let recordSession: Bool
    
    static func `default`() -> SessionSettings {
        return SessionSettings(
            enableVoiceChat: false,
            enableScreenSharing: false,
            enableRealTimeEditing: true,
            enablePresenceIndicators: true,
            maxParticipants: 10,
            requireApproval: false,
            recordSession: false
        )
    }
}
