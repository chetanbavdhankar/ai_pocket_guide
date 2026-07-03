// SettingsView.swift — AI Pocket Arena
// Controls app preferences and displays unlocked badges.

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showResetConfirmation = false
    
    private var profile: UserProfile {
        if let existing = profiles.first { return existing }
        let newProfile = UserProfile()
        modelContext.insert(newProfile)
        return newProfile
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Badges Section
                badgesSection
                
                // Audio / Haptics preferences
                preferencesSection
                
                // Account / Reset section
                dangerSection
            }
            .padding(.vertical)
        }
        .background(DesignTokens.bg)
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Settings & Achievements")
                    .font(DesignTokens.display(18))
                    .foregroundStyle(DesignTokens.text)
            }
        }
        .alert("Reset All Progress?", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) {
                resetAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all your session history, XP, levels, and unlocked achievements. This action cannot be undone.")
        }
    }
    
    // MARK: - Subviews
    
    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements & Badges")
                .font(DesignTokens.display(16))
                .foregroundStyle(DesignTokens.text)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(Badge.allCases) { badge in
                    let isUnlocked = profile.unlockedBadges.contains(badge.rawValue)
                    
                    VStack(spacing: 6) {
                        Text(badge.icon)
                            .font(.system(size: 24))
                            .grayscale(isUnlocked ? 0 : 1)
                            .opacity(isUnlocked ? 1 : 0.25)
                        
                        Text(badge.displayName)
                            .font(DesignTokens.mono(8))
                            .foregroundStyle(isUnlocked ? DesignTokens.text : DesignTokens.text3)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(height: 22)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isUnlocked ? DesignTokens.surface : DesignTokens.surface2.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.radius)
                            .stroke(isUnlocked ? DesignTokens.accent.opacity(0.2) : DesignTokens.border.opacity(0.1), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preferences")
                .font(DesignTokens.display(16))
                .foregroundStyle(DesignTokens.text)
                .padding(.horizontal)
            
            VStack(spacing: 1) {
                // Haptics Toggle
                Toggle(isOn: Bindable(profile).hapticsEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: "hand.tap.fill")
                            .foregroundStyle(DesignTokens.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Haptic Feedback")
                                .font(DesignTokens.body(14, weight: .semibold))
                                .foregroundStyle(DesignTokens.text)
                            Text("Vibrate on answers and milestones")
                                .font(DesignTokens.body(11))
                                .foregroundStyle(DesignTokens.text2)
                        }
                    }
                }
                .padding()
                .background(DesignTokens.surface)
                .onChange(of: profile.hapticsEnabled) { _, newValue in
                    HapticsManager.shared.setEnabled(newValue)
                }
                
                Divider().overlay(DesignTokens.border)
                
                // SFX Toggle
                Toggle(isOn: Bindable(profile).sfxEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundStyle(DesignTokens.accent2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sound Effects")
                                .font(DesignTokens.body(14, weight: .semibold))
                                .foregroundStyle(DesignTokens.text)
                            Text("Play positive or negative audio cues")
                                .font(DesignTokens.body(11))
                                .foregroundStyle(DesignTokens.text2)
                        }
                    }
                }
                .padding()
                .background(DesignTokens.surface)
                .onChange(of: profile.sfxEnabled) { _, newValue in
                    SFXManager.shared.setEnabled(newValue)
                }
                
                Divider().overlay(DesignTokens.border)
                
                // Free Play Toggle
                Toggle(isOn: Bindable(profile).freePlayMode) {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.open.fill")
                            .foregroundStyle(DesignTokens.accent4)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Free Play Mode")
                                .font(DesignTokens.body(14, weight: .semibold))
                                .foregroundStyle(DesignTokens.text)
                            Text("Disable content progression gating")
                                .font(DesignTokens.body(11))
                                .foregroundStyle(DesignTokens.text2)
                        }
                    }
                }
                .padding()
                .background(DesignTokens.surface)
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radius)
                    .stroke(DesignTokens.border, lineWidth: 1)
            )
            .padding(.horizontal)
        }
    }
    
    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Danger Zone")
                .font(DesignTokens.display(16))
                .foregroundStyle(DesignTokens.text)
                .padding(.horizontal)
            
            Button {
                showResetConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Reset All Progress")
                }
                .font(DesignTokens.display(14))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(DesignTokens.accent3)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radius))
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Core Operations
    
    private func resetAllData() {
        // Delete all progress records
        let progressFetch = FetchDescriptor<ConceptProgress>()
        if let records = try? modelContext.fetch(progressFetch) {
            for record in records {
                modelContext.delete(record)
            }
        }
        
        // Reset user profile stats
        profile.xp = 0
        profile.level = 1
        profile.currentStreak = 0
        profile.longestStreak = 0
        profile.lastActiveDate = nil
        profile.streakFreezeAvailable = false
        profile.totalSessionsPlayed = 0
        profile.totalCorrectAnswers = 0
        profile.totalQuestionsAnswered = 0
        profile.unlockedBadges = []
        
        try? modelContext.save()
        
        HapticsManager.shared.incorrect()
        SFXManager.shared.incorrect()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [ConceptProgress.self, UserProfile.self], inMemory: true)
}
