import Cocoa
import UserNotifications

// MARK: - Shell Command Runner

class ShellRunner {
    static let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"

    static func run(_ command: String, completion: @escaping (String, Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            let pipe = Pipe()

            process.executableURL = URL(fileURLWithPath: shell)
            // Use login + interactive shell so profile-defined functions/aliases are loaded
            process.arguments = ["-l", "-i", "-c", command]
            process.standardOutput = pipe
            process.standardError = pipe
            // Prevent the child shell from attaching to a TTY
            process.environment = ProcessInfo.processInfo.environment
            process.environment?["TERM"] = "dumb"

            do {
                try process.run()
                process.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let success = process.terminationStatus == 0
                DispatchQueue.main.async { completion(output, success) }
            } catch {
                DispatchQueue.main.async { completion("Error: \(error.localizedDescription)", false) }
            }
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var statusMenuItem: NSMenuItem!
    private var uptimeMenuItem: NSMenuItem!
    private var ipMenuItem: NSMenuItem!
    private var startMenuItem: NSMenuItem!
    private var hibernateMenuItem: NSMenuItem!
    private var refreshTimer: Timer?
    private var hasShownUptimeWarning = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "server.rack", accessibilityDescription: "DevBox")
            // Fallback for older macOS without SF Symbols
            if button.image == nil {
                button.title = "📦"
            }
        }

        buildMenu()
        refreshStatus()

        // Auto-refresh status every 60 seconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.refreshStatus()
        }
    }

    private func buildMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false

        statusMenuItem = NSMenuItem(title: "Status: checking…", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)

        uptimeMenuItem = NSMenuItem(title: "Uptime: …", action: nil, keyEquivalent: "")
        uptimeMenuItem.isEnabled = false
        uptimeMenuItem.isHidden = true
        menu.addItem(uptimeMenuItem)

        ipMenuItem = NSMenuItem(title: "IP: …", action: nil, keyEquivalent: "")
        ipMenuItem.isEnabled = false
        menu.addItem(ipMenuItem)

        menu.addItem(NSMenuItem.separator())

        startMenuItem = NSMenuItem(title: "▶ Start DevBox", action: #selector(startDevBox), keyEquivalent: "s")
        startMenuItem.target = self
        startMenuItem.isEnabled = false
        menu.addItem(startMenuItem)

        hibernateMenuItem = NSMenuItem(title: "⏸ Hibernate DevBox", action: #selector(hibernateDevBox), keyEquivalent: "h")
        hibernateMenuItem.target = self
        hibernateMenuItem.isEnabled = false
        menu.addItem(hibernateMenuItem)

        menu.addItem(NSMenuItem.separator())

        let refreshItem = NSMenuItem(title: "↻ Refresh", action: #selector(refreshStatus), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc func refreshStatus() {
        statusMenuItem.title = "Status: checking…"
        ipMenuItem.title = "IP: checking…"
        setActionItemsEnabled(false)

        ShellRunner.run("devbox-status") { [weak self] output, success in
            guard let self = self else { return }
            if success {
                let lines = output.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }
                let status = lines.first ?? output
                self.statusMenuItem.title = "Status: \(status)"

                // Parse uptime from second line if present (e.g., "Uptime: 3h 15m")
                let uptimeLine = lines.count > 1 ? lines[1] : nil
                self.updateUptime(status: status, uptimeLine: uptimeLine)
            } else {
                self.statusMenuItem.title = "Status: ⚠️ error"
                self.uptimeMenuItem.isHidden = true
            }
            self.updateActionItems()
        }

        ShellRunner.run("devbox-ip") { [weak self] output, success in
            guard let self = self else { return }
            if success && !output.isEmpty {
                self.ipMenuItem.title = "IP: \(output)"
                self.ipMenuItem.action = #selector(self.copyIP)
                self.ipMenuItem.target = self
                self.ipMenuItem.isEnabled = true
            } else {
                self.ipMenuItem.title = "IP: unavailable"
                self.ipMenuItem.action = nil
                self.ipMenuItem.isEnabled = false
            }
        }
    }

    @objc func copyIP() {
        let ip = ipMenuItem.title.replacingOccurrences(of: "IP: ", with: "")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(ip, forType: .string)
    }

    @objc func startDevBox() {
        statusMenuItem.title = "Status: starting…"
        setActionItemsEnabled(false)

        ShellRunner.run("devbox-start") { [weak self] output, success in
            guard let self = self else { return }
            if success {
                self.showNotification(title: "DevBox Started", body: output)
            } else {
                self.showNotification(title: "DevBox Start Failed", body: output)
            }
            self.refreshStatus()
        }
    }

    @objc func hibernateDevBox() {
        statusMenuItem.title = "Status: hibernating…"
        setActionItemsEnabled(false)

        ShellRunner.run("devbox-hibernate") { [weak self] output, success in
            guard let self = self else { return }
            if success {
                self.showNotification(title: "DevBox Hibernated", body: output)
            } else {
                self.showNotification(title: "DevBox Hibernate Failed", body: output)
            }
            self.refreshStatus()
        }
    }

    private func setActionItemsEnabled(_ enabled: Bool) {
        startMenuItem.isEnabled = enabled
        hibernateMenuItem.isEnabled = enabled
    }

    private func updateActionItems() {
        let isRunning = statusMenuItem.title.lowercased().contains("running")
        startMenuItem.isEnabled = !isRunning
        hibernateMenuItem.isEnabled = isRunning
    }

    private func updateUptime(status: String, uptimeLine: String?) {
        let isRunning = status.lowercased().contains("running")

        if isRunning, let uptimeLine = uptimeLine, uptimeLine.lowercased().hasPrefix("uptime:") {
            uptimeMenuItem.title = uptimeLine
            uptimeMenuItem.isHidden = false

            // Parse hours from uptime string to check threshold (e.g., "Uptime: 5h 12m")
            let overThreshold = parseHours(from: uptimeLine) >= 5

            if overThreshold {
                uptimeMenuItem.title = "⚠️ \(uptimeLine) (over 5h!)"
            }

            // Update menu bar icon
            if let button = statusItem.button {
                if overThreshold {
                    button.image = NSImage(systemSymbolName: "exclamationmark.server.rack", accessibilityDescription: "DevBox Warning")
                    if button.image == nil { button.title = "⚠️" }
                } else {
                    button.image = NSImage(systemSymbolName: "server.rack", accessibilityDescription: "DevBox")
                    if button.image == nil { button.title = "📦" }
                }
            }

            // Send notification once when threshold is crossed
            if overThreshold && !hasShownUptimeWarning {
                hasShownUptimeWarning = true
                showNotification(
                    title: "⚠️ DevBox Running Over 5 Hours",
                    body: "Your VM has been running for \(uptimeLine.replacingOccurrences(of: "Uptime: ", with: "")). Consider hibernating to save costs."
                )
            }
        } else {
            uptimeMenuItem.isHidden = true
            hasShownUptimeWarning = false
            if let button = statusItem.button {
                button.image = NSImage(systemSymbolName: "server.rack", accessibilityDescription: "DevBox")
                if button.image == nil { button.title = "📦" }
            }
        }
    }

    private func parseHours(from uptimeString: String) -> Int {
        // Parse "Uptime: 5h 12m" -> 5
        let pattern = "(\\d+)h"
        if let range = uptimeString.range(of: pattern, options: .regularExpression),
           let hours = Int(uptimeString[range].dropLast()) {
            return hours
        }
        return 0
    }

    private func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Main Entry Point

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
