//
//  AppIntegrity.swift
//  PlayCover
//

import Foundation

class AppIntegrity : ObservableObject {
    
    @Published var integrityOff : Bool = !AppIntegrity.insideAppsFolder
    
    func verifyAppIntegrity() {
        integrityOff = !AppIntegrity.insideAppsFolder
    }
    
    func moveToApps() {
        do {
            if fm.fileExists(atPath: AppIntegrity.expectedUrl.path){
                try fm.delete(at: AppIntegrity.expectedUrl)
            }
            try fm.copyItem(at: AppIntegrity.appUrl!, to: AppIntegrity.expectedUrl)
            URL(fileURLWithPath: AppIntegrity.expectedUrl.path).showInFinder()
            try fm.delete(at: AppIntegrity.appUrl!)
            exit(0);
        } catch {
            Log.shared.error(error)
        }
    }
    
    private static var appUrl : URL? {
        Bundle.main.resourceURL?.deletingLastPathComponent().deletingLastPathComponent()
    }
    
    private static var expectedUrl = URL(fileURLWithPath: "/Applications/PlayCover.app")
    
    private static var insideAppsFolder : Bool {
        if let url = appUrl {
            return url.path.contains("Xcode") || url.path.contains(expectedUrl.path)
        }
        return false
    }
    
}
