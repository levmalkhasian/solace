//
//  AlarmSound.swift
//  Solace
//
//  The list of wake-alarm sounds the user can pick from. Each case maps to
//  an optional bundled audio file; if the file isn't present, both AlarmKit
//  and the in-app siren fall back to a default system sound.
//
//  To ship real audio, drop a matching file (same basename, .caf or .mp3)
//  into the Solace/Sounds/ folder. The folder is synced via Xcode's
//  synchronized-folder support so new files are picked up automatically.
//

import Foundation
import AlarmKit
import ActivityKit

enum AlarmSound: String, CaseIterable, Identifiable {
    case systemDefault = "default"
    case classic
    case chime
    case buzzer
    case gentle

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .systemDefault: return "Default"
        case .classic: return "Classic"
        case .chime: return "Chime"
        case .buzzer: return "Buzzer"
        case .gentle: return "Gentle"
        }
    }

    var icon: String {
        switch self {
        case .systemDefault: return "bell.fill"
        case .classic: return "alarm.fill"
        case .chime: return "bell.badge.fill"
        case .buzzer: return "exclamationmark.triangle.fill"
        case .gentle: return "leaf.fill"
        }
    }

    /// Filename (no extension) for a bundled audio file. `.systemDefault`
    /// always returns nil so it always falls back to the OS default.
    var bundleFileName: String? {
        switch self {
        case .systemDefault: return nil
        default: return rawValue
        }
    }

    /// URL to the bundled audio file, or nil if no matching resource exists.
    var bundleURL: URL? {
        guard let name = bundleFileName else { return nil }
        return Bundle.main.url(forResource: name, withExtension: "caf")
            ?? Bundle.main.url(forResource: name, withExtension: "mp3")
            ?? Bundle.main.url(forResource: name, withExtension: "wav")
    }

    @available(iOS 26.0, *)
    var alertKitSound: AlertConfiguration.AlertSound {
        if let name = bundleFileName, bundleURL != nil {
            return .named(name)
        }
        return .default
    }
}
