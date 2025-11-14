//
//  CollaborativeReviewView.swift
//  AFHAM
//
//  Collaborative review mode with comments and revision history
//

import SwiftUI

struct CollaborativeReviewView: View {
    @Binding var panel: DocumentPanel
    @State private var selectedRevision: Revision?
    @State private var showCommentComposer: Bool = false
    @State private var newCommentText: String = ""
    @State private var commentPosition: String = ""

    var body: some View {
        HStack(spacing: 0) {
            // Content View with Comments
            contentWithCommentsView
                .frame(minWidth: 500)

            Divider()

            // Sidebar: Comments & Revisions
            sidebarView
                .frame(minWidth: 300, idealWidth: 350, maxWidth: 400)
        }
        .sheet(isPresented: $showCommentComposer) {
            CommentComposerSheet(
                commentText: $newCommentText,
                position: $commentPosition,
                onSubmit: addComment
            )
        }
    }

    // MARK: - Content with Comments View

    private var contentWithCommentsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(panel.documentMetadata.fileName)
                            .font(.title2.bold())

                        HStack(spacing: 12) {
                            Label("\(panel.comments.count) comments", systemImage: "bubble.left.and.bubble.right")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Label("\(panel.revisionHistory.count) revisions", systemImage: "clock.arrow.circlepath")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Button(action: { showCommentComposer = true }) {
                        Label("Add Comment", systemImage: "plus.bubble")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color(.secondarySystemBackground))

                Divider()

                // Content with inline comments
                if let latestRevision = panel.revisionHistory.last {
                    contentView(for: latestRevision)
                } else {
                    Text("No content available")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
        }
    }

    private func contentView(for revision: Revision) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(revision.content.components(separatedBy: "\n\n").indices, id: \.self) { index in
                let paragraph = revision.content.components(separatedBy: "\n\n")[index]

                VStack(alignment: .leading, spacing: 8) {
                    // Paragraph
                    Text(paragraph)
                        .font(.body)
                        .padding()
                        .background(hasComments(at: "paragraph_\(index)") ? Color.yellow.opacity(0.1) : Color.clear)
                        .cornerRadius(8)
                        .contextMenu {
                            Button(action: {
                                commentPosition = "paragraph_\(index)"
                                showCommentComposer = true
                            }) {
                                Label("Add Comment", systemImage: "bubble.left")
                            }
                        }

                    // Inline comments
                    if hasComments(at: "paragraph_\(index)") {
                        ForEach(getComments(at: "paragraph_\(index)")) { comment in
                            InlineCommentView(comment: comment, onResolve: {
                                resolveComment(comment)
                            })
                        }
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - Sidebar View

    private var sidebarView: some View {
        VStack(spacing: 0) {
            // Tabs
            Picker("View", selection: $selectedTab) {
                Text("Comments").tag(SidebarTab.comments)
                Text("Revisions").tag(SidebarTab.revisions)
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            // Content
            if selectedTab == .comments {
                commentsListView
            } else {
                revisionsListView
            }
        }
        .background(Color(.secondarySystemBackground))
    }

    @State private var selectedTab: SidebarTab = .comments

    enum SidebarTab {
        case comments
        case revisions
    }

    // MARK: - Comments List

    private var commentsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Filter options
                HStack {
                    Picker("Filter", selection: $commentFilter) {
                        Text("All").tag(CommentFilter.all)
                        Text("Open").tag(CommentFilter.open)
                        Text("Resolved").tag(CommentFilter.resolved)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)

                ForEach(filteredComments) { comment in
                    CommentCardView(comment: comment, onResolve: {
                        resolveComment(comment)
                    }, onReply: {
                        replyToComment(comment)
                    })
                }

                if filteredComments.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("No \(commentFilter == .all ? "" : commentFilter.rawValue.lowercased()) comments")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .padding()
        }
    }

    @State private var commentFilter: CommentFilter = .all

    enum CommentFilter: String {
        case all = "All"
        case open = "Open"
        case resolved = "Resolved"
    }

    private var filteredComments: [Comment] {
        switch commentFilter {
        case .all:
            return panel.comments
        case .open:
            return panel.comments.filter { $0.status == .open || $0.status == .inProgress }
        case .resolved:
            return panel.comments.filter { $0.status == .resolved }
        }
    }

    // MARK: - Revisions List

    private var revisionsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(panel.revisionHistory.reversed()) { revision in
                    RevisionCardView(
                        revision: revision,
                        isSelected: selectedRevision?.id == revision.id
                    ) {
                        selectedRevision = revision
                    } onRestore: {
                        restoreRevision(revision)
                    }
                }

                if panel.revisionHistory.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("No revision history")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .padding()
        }
    }

    // MARK: - Helper Functions

    private func hasComments(at position: String) -> Bool {
        panel.comments.contains { $0.position?.section == position }
    }

    private func getComments(at position: String) -> [Comment] {
        panel.comments.filter { $0.position?.section == position }
    }

    private func addComment() {
        guard !newCommentText.isEmpty else { return }

        let comment = Comment(
            author: "Current User", // TODO: Get from app state
            content: newCommentText,
            status: .open
        )

        var updatedComment = comment
        if !commentPosition.isEmpty {
            updatedComment.position = Comment.CommentPosition(section: commentPosition)
        }

        panel.comments.append(updatedComment)

        // Reset
        newCommentText = ""
        commentPosition = ""
        showCommentComposer = false
    }

    private func resolveComment(_ comment: Comment) {
        if let index = panel.comments.firstIndex(where: { $0.id == comment.id }) {
            panel.comments[index].status = .resolved
        }
    }

    private func replyToComment(_ comment: Comment) {
        // TODO: Implement reply functionality
    }

    private func restoreRevision(_ revision: Revision) {
        // Create a new revision from current state
        if let currentRevision = panel.revisionHistory.last {
            let newRevision = Revision(
                version: panel.revisionHistory.count + 1,
                content: currentRevision.content,
                author: "Current User",
                changeDescription: "Restored from version \(revision.version)"
            )
            panel.revisionHistory.append(newRevision)
        }

        // Restore the selected revision
        let restoredRevision = Revision(
            version: panel.revisionHistory.count + 1,
            content: revision.content,
            author: "Current User",
            changeDescription: "Restored version \(revision.version)"
        )
        panel.revisionHistory.append(restoredRevision)
    }
}

// MARK: - Inline Comment View

struct InlineCommentView: View {
    let comment: Comment
    let onResolve: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.author)
                        .font(.caption.bold())

                    Text(comment.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Text(comment.content)
                    .font(.caption)

                if comment.status != .resolved {
                    Button("Resolve", action: onResolve)
                        .font(.caption2)
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
        .padding(.leading, 20)
    }

    private var statusColor: Color {
        switch comment.status {
        case .open:
            return .orange
        case .resolved:
            return .green
        case .inProgress:
            return .blue
        }
    }
}

// MARK: - Comment Card View

struct CommentCardView: View {
    let comment: Comment
    let onResolve: () -> Void
    let onReply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(comment.author.prefix(1).uppercased())
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(comment.author)
                            .font(.subheadline.bold())

                        Spacer()

                        statusBadge
                    }

                    Text(comment.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let position = comment.position?.section {
                        Text("📍 \(position)")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }

            Text(comment.content)
                .font(.body)

            // Tags
            if !comment.tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(comment.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
            }

            // Replies
            if !comment.replies.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(comment.replies) { reply in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "arrowshape.turn.up.left.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(reply.author)
                                    .font(.caption.bold())

                                Text(reply.content)
                                    .font(.caption)
                            }
                        }
                        .padding(.leading, 12)
                    }
                }
            }

            // Actions
            HStack(spacing: 12) {
                if comment.status != .resolved {
                    Button(action: onResolve) {
                        Label("Resolve", systemImage: "checkmark.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Button(action: onReply) {
                    Label("Reply", systemImage: "arrowshape.turn.up.left")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)

            Text(comment.status.rawValue)
                .font(.caption2)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .cornerRadius(12)
    }

    private var statusColor: Color {
        switch comment.status {
        case .open:
            return .orange
        case .resolved:
            return .green
        case .inProgress:
            return .blue
        }
    }
}

// MARK: - Revision Card View

struct RevisionCardView: View {
    let revision: Revision
    let isSelected: Bool
    let onTap: () -> Void
    let onRestore: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("v\(revision.version)")
                        .font(.headline)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }

                Text(revision.changeDescription)
                    .font(.subheadline)
                    .lineLimit(2)

                HStack {
                    Text(revision.author)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(revision.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let branchName = revision.branchName {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.branch")
                            .font(.caption2)
                        Text(branchName)
                            .font(.caption2)
                    }
                    .foregroundColor(.purple)
                }

                Button(action: onRestore) {
                    Label("Restore this version", systemImage: "clock.arrow.circlepath")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Comment Composer Sheet

struct CommentComposerSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var commentText: String
    @Binding var position: String
    let onSubmit: () -> Void

    @State private var selectedTags: [String] = []

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // Comment Text
                VStack(alignment: .leading, spacing: 8) {
                    Text("Comment")
                        .font(.headline)

                    TextEditor(text: $commentText)
                        .frame(minHeight: 150)
                        .padding(8)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                }

                // Position
                if !position.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Position")
                            .font(.headline)

                        Text(position)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(6)
                    }
                }

                // Tags
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags (optional)")
                        .font(.headline)

                    HStack {
                        ForEach(["Question", "Suggestion", "Issue", "Praise"], id: \.self) { tag in
                            Button(action: { toggleTag(tag) }) {
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedTags.contains(tag) ? Color.blue : Color(.tertiarySystemBackground))
                                    .foregroundColor(selectedTags.contains(tag) ? .white : .primary)
                                    .cornerRadius(16)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Add Comment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        onSubmit()
                        dismiss()
                    }
                    .disabled(commentText.isEmpty)
                }
            }
        }
    }

    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.removeAll { $0 == tag }
        } else {
            selectedTags.append(tag)
        }
    }
}
