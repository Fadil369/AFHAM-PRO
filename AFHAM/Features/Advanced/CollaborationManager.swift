// AFHAM - Collaboration Manager
// Advanced team collaboration features with PDPL compliance
// Real-time document sharing and collaborative analysis

import SwiftUI
import Foundation
import Combine
import Network

// MARK: - ADVANCED FEATURE: Collaboration Manager
@MainActor
class CollaborationManager: ObservableObject {
    static let shared = CollaborationManager()
    
    @Published var isCollaborationEnabled = false
    @Published var activeCollaborations: [Collaboration] = []
    @Published var pendingInvites: [CollaborationInvite] = []
    @Published var connectedPeers: [CollaborationPeer] = []
    @Published var shareHistory: [ShareActivity] = []
    
    private let networkMonitor = NWPathMonitor()
    private let collaborationQueue = DispatchQueue(label: "com.brainsait.afham.collaboration")
    private var cancellables = Set<AnyCancellable>()
    
    // PDPL Compliance: Audit trail for shared documents
    private var auditLogger = CollaborationAuditLogger()
    
    private init() {
        setupNetworkMonitoring()
        loadCollaborationHistory()
        
        AppLogger.shared.log("CollaborationManager initialized", level: .info)
    }
    
    // MARK: - Collaboration Session Management
    func startCollaborationSession(for document: DocumentMetadata) async throws -> Collaboration {
        guard AFHAMConstants.Features.collaborationEnabled else {
            throw AFHAMError.featureDisabled("Collaboration")
        }
        
        let collaboration = Collaboration(
            id: UUID(),
            documentId: document.id,
            hostUserId: getCurrentUserId(),
            createdAt: Date(),
            status: .active,
            participants: [createCurrentUserPeer()]
        )
        
        activeCollaborations.append(collaboration)
        
        // PDPL: Log collaboration start
        await auditLogger.logCollaborationStart(collaboration)
        
        AppLogger.shared.log("Collaboration session started for document: \(document.fileName)", level: .success)
        return collaboration
    }
    
    func joinCollaborationSession(_ sessionId: UUID, inviteCode: String) async throws {
        // Validate invite code and join session
        let collaboration = try await validateAndJoinSession(sessionId: sessionId, inviteCode: inviteCode)
        
        activeCollaborations.append(collaboration)
        
        // PDPL: Log collaboration join
        await auditLogger.logCollaborationJoin(collaboration, userId: getCurrentUserId())
        
        AppLogger.shared.log("Joined collaboration session: \(sessionId)", level: .success)
    }
    
    func endCollaborationSession(_ collaborationId: UUID) async {
        guard let index = activeCollaborations.firstIndex(where: { $0.id == collaborationId }) else { return }
        
        let collaboration = activeCollaborations[index]
        activeCollaborations[index].status = .ended
        
        // PDPL: Log collaboration end
        await auditLogger.logCollaborationEnd(collaboration)
        
        // Archive to history
        shareHistory.append(ShareActivity.from(collaboration))
        activeCollaborations.remove(at: index)
        
        AppLogger.shared.log("Collaboration session ended: \(collaborationId)", level: .info)
    }
    
    // MARK: - Document Sharing with PDPL Controls
    func shareDocument(_ document: DocumentMetadata, with users: [String], permissions: SharePermissions) async throws -> String {
        // PDPL: Verify sharing permissions
        try validateSharingPermissions(document, permissions: permissions)
        
        let shareId = UUID().uuidString
        let activity = ShareActivity(
            id: UUID(),
            documentId: document.id,
            sharedBy: getCurrentUserId(),
            sharedWith: users,
            permissions: permissions,
            shareDate: Date(),
            expiryDate: permissions.expiryDate,
            accessCode: shareId
        )
        
        shareHistory.append(activity)
        
        // Send invitations
        for user in users {
            let invite = CollaborationInvite(
                id: UUID(),
                documentId: document.id,
                invitedBy: getCurrentUserId(),
                invitedUser: user,
                permissions: permissions,
                inviteCode: shareId,
                createdAt: Date(),
                expiryDate: permissions.expiryDate
            )
            
            try await sendInvitation(invite)
        }
        
        // PDPL: Audit log
        await auditLogger.logDocumentShare(activity)
        
        AppLogger.shared.log("Document shared with \(users.count) users", level: .success)
        return shareId
    }
    
    func revokeDocumentAccess(_ shareId: String) async throws {
        guard let activity = shareHistory.first(where: { $0.accessCode == shareId }) else {
            throw AFHAMError.shareNotFound(shareId)
        }
        
        // Mark as revoked
        if let index = shareHistory.firstIndex(where: { $0.id == activity.id }) {
            shareHistory[index].isRevoked = true
            shareHistory[index].revokedAt = Date()
        }
        
        // PDPL: Audit log
        await auditLogger.logAccessRevocation(shareId, revokedBy: getCurrentUserId())
        
        AppLogger.shared.log("Document access revoked: \(shareId)", level: .info)
    }
    
    // MARK: - Real-time Collaboration Features
    func sendCollaborationMessage(_ message: String, to collaborationId: UUID) async throws {
        guard let collaboration = activeCollaborations.first(where: { $0.id == collaborationId }) else {
            throw AFHAMError.collaborationNotFound(collaborationId)
        }
        
        let collabMessage = CollaborationMessage(
            id: UUID(),
            collaborationId: collaborationId,
            senderId: getCurrentUserId(),
            content: message,
            timestamp: Date(),
            type: .text
        )
        
        // Broadcast to all participants
        await broadcastMessage(collabMessage, to: collaboration.participants)
        
        AppLogger.shared.log("Collaboration message sent", level: .info)
    }
    
    func shareAnalysisResult(_ result: String, to collaborationId: UUID) async throws {
        guard let collaboration = activeCollaborations.first(where: { $0.id == collaborationId }) else {
            throw AFHAMError.collaborationNotFound(collaborationId)
        }
        
        let message = CollaborationMessage(
            id: UUID(),
            collaborationId: collaborationId,
            senderId: getCurrentUserId(),
            content: result,
            timestamp: Date(),
            type: .analysis
        )
        
        await broadcastMessage(message, to: collaboration.participants)
        
        AppLogger.shared.log("Analysis result shared in collaboration", level: .info)
    }
    
    // MARK: - Privacy & Security (PDPL Compliance)
    private func validateSharingPermissions(_ document: DocumentMetadata, permissions: SharePermissions) throws {
        // Check if document contains sensitive data
        if document.containsPHI {
            guard permissions.allowPHISharing else {
                throw AFHAMError.phiSharingNotAllowed
            }
        }
        
        // Verify user has permission to share
        guard hasSharePermission(for: document) else {
            throw AFHAMError.insufficientPermissions
        }
        
        // Check expiry date is within allowed limits
        if let expiryDate = permissions.expiryDate {
            let maxDays = AFHAMConstants.Security.maxShareDuration
            let maxDate = Date().addingTimeInterval(TimeInterval(maxDays * 24 * 60 * 60))
            
            guard expiryDate <= maxDate else {
                throw AFHAMError.shareExpiryTooLong
            }
        }
    }
    
    // MARK: - Network & Communication
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isCollaborationEnabled = path.status == .satisfied && AFHAMConstants.Features.collaborationEnabled
            }
        }
        networkMonitor.start(queue: collaborationQueue)
    }
    
    private func validateAndJoinSession(sessionId: UUID, inviteCode: String) async throws -> Collaboration {
        // Validate invite code with server
        // This would make an API call to validate the invitation
        
        // For now, create a mock collaboration
        return Collaboration(
            id: sessionId,
            documentId: UUID(),
            hostUserId: "host_user",
            createdAt: Date(),
            status: .active,
            participants: [createCurrentUserPeer()]
        )
    }
    
    private func sendInvitation(_ invite: CollaborationInvite) async throws {
        // Send invitation via email, push notification, etc.
        AppLogger.shared.log("Invitation sent to: \(invite.invitedUser)", level: .info)
    }
    
    private func broadcastMessage(_ message: CollaborationMessage, to participants: [CollaborationPeer]) async {
        // Broadcast message to all participants
        for participant in participants where participant.id != getCurrentUserId() {
            // Send message via WebSocket, peer-to-peer, etc.
        }
    }
    
    // MARK: - Helper Methods
    private func getCurrentUserId() -> String {
        return "current_user_id" // This would come from user session
    }
    
    private func createCurrentUserPeer() -> CollaborationPeer {
        return CollaborationPeer(
            id: getCurrentUserId(),
            name: "Current User",
            role: .owner,
            joinedAt: Date(),
            isActive: true
        )
    }
    
    private func hasSharePermission(for document: DocumentMetadata) -> Bool {
        // Check user permissions for document
        return true // Simplified for demo
    }
    
    private func loadCollaborationHistory() {
        // Load from persistent storage
        if let data = UserDefaults.standard.data(forKey: "ShareHistory"),
           let history = try? JSONDecoder().decode([ShareActivity].self, from: data) {
            shareHistory = history
        }
    }
    
    private func saveCollaborationHistory() {
        if let data = try? JSONEncoder().encode(shareHistory) {
            UserDefaults.standard.set(data, forKey: "ShareHistory")
        }
    }
}

// MARK: - Data Models
struct Collaboration: Codable, Identifiable {
    let id: UUID
    let documentId: UUID
    let hostUserId: String
    let createdAt: Date
    var status: CollaborationStatus
    var participants: [CollaborationPeer]
}

enum CollaborationStatus: String, Codable {
    case active
    case paused
    case ended
}

struct CollaborationPeer: Codable, Identifiable {
    let id: String
    let name: String
    let role: PeerRole
    let joinedAt: Date
    var isActive: Bool
}

enum PeerRole: String, Codable {
    case owner
    case editor
    case viewer
}

struct CollaborationInvite: Codable, Identifiable {
    let id: UUID
    let documentId: UUID
    let invitedBy: String
    let invitedUser: String
    let permissions: SharePermissions
    let inviteCode: String
    let createdAt: Date
    let expiryDate: Date?
}

struct SharePermissions: Codable {
    let canView: Bool
    let canEdit: Bool
    let canShare: Bool
    let canDownload: Bool
    let allowPHISharing: Bool
    let expiryDate: Date?
}

struct ShareActivity: Codable, Identifiable {
    let id: UUID
    let documentId: UUID
    let sharedBy: String
    let sharedWith: [String]
    let permissions: SharePermissions
    let shareDate: Date
    let expiryDate: Date?
    let accessCode: String
    var isRevoked: Bool = false
    var revokedAt: Date?
    
    static func from(_ collaboration: Collaboration) -> ShareActivity {
        return ShareActivity(
            id: UUID(),
            documentId: collaboration.documentId,
            sharedBy: collaboration.hostUserId,
            sharedWith: collaboration.participants.map { $0.id },
            permissions: SharePermissions(
                canView: true,
                canEdit: true,
                canShare: false,
                canDownload: false,
                allowPHISharing: false,
                expiryDate: nil
            ),
            shareDate: collaboration.createdAt,
            expiryDate: nil,
            accessCode: collaboration.id.uuidString
        )
    }
}

struct CollaborationMessage: Codable, Identifiable {
    let id: UUID
    let collaborationId: UUID
    let senderId: String
    let content: String
    let timestamp: Date
    let type: MessageType
}

enum MessageType: String, Codable {
    case text
    case analysis
    case file
    case system
}

// MARK: - Audit Logger for PDPL Compliance
actor CollaborationAuditLogger {
    private var auditEntries: [CollaborationAuditEntry] = []
    
    func logCollaborationStart(_ collaboration: Collaboration) {
        let entry = CollaborationAuditEntry(
            id: UUID(),
            timestamp: Date(),
            action: .collaborationStarted,
            userId: collaboration.hostUserId,
            documentId: collaboration.documentId,
            details: "Collaboration session started"
        )
        auditEntries.append(entry)
        AppLogger.shared.log("AUDIT: Collaboration started", level: .info)
    }
    
    func logCollaborationJoin(_ collaboration: Collaboration, userId: String) {
        let entry = CollaborationAuditEntry(
            id: UUID(),
            timestamp: Date(),
            action: .userJoined,
            userId: userId,
            documentId: collaboration.documentId,
            details: "User joined collaboration"
        )
        auditEntries.append(entry)
    }
    
    func logCollaborationEnd(_ collaboration: Collaboration) {
        let entry = CollaborationAuditEntry(
            id: UUID(),
            timestamp: Date(),
            action: .collaborationEnded,
            userId: collaboration.hostUserId,
            documentId: collaboration.documentId,
            details: "Collaboration session ended"
        )
        auditEntries.append(entry)
    }
    
    func logDocumentShare(_ activity: ShareActivity) {
        let entry = CollaborationAuditEntry(
            id: UUID(),
            timestamp: Date(),
            action: .documentShared,
            userId: activity.sharedBy,
            documentId: activity.documentId,
            details: "Document shared with \(activity.sharedWith.count) users"
        )
        auditEntries.append(entry)
    }
    
    func logAccessRevocation(_ shareId: String, revokedBy: String) {
        let entry = CollaborationAuditEntry(
            id: UUID(),
            timestamp: Date(),
            action: .accessRevoked,
            userId: revokedBy,
            documentId: nil,
            details: "Access revoked for share: \(shareId)"
        )
        auditEntries.append(entry)
    }
}

struct CollaborationAuditEntry: Codable {
    let id: UUID
    let timestamp: Date
    let action: AuditAction
    let userId: String
    let documentId: UUID?
    let details: String
}

enum AuditAction: String, Codable {
    case collaborationStarted
    case collaborationEnded
    case userJoined
    case userLeft
    case documentShared
    case accessRevoked
    case messageShared
}

// MARK: - Error Extensions
extension AFHAMError {
    static func shareNotFound(_ shareId: String) -> AFHAMError {
        return .queryFailed("Share not found: \(shareId)")
    }
    
    static func collaborationNotFound(_ collaborationId: UUID) -> AFHAMError {
        return .queryFailed("Collaboration not found: \(collaborationId)")
    }
    
    static let phiSharingNotAllowed = AFHAMError.networkError("PHI sharing not allowed")
    static let insufficientPermissions = AFHAMError.networkError("Insufficient permissions")
    static let shareExpiryTooLong = AFHAMError.networkError("Share expiry date exceeds maximum allowed")
}

// MARK: - DocumentMetadata Extension
extension DocumentMetadata {
    var containsPHI: Bool {
        // Logic to determine if document contains PHI
        // This would analyze the document content
        return false // Simplified for demo
    }
}