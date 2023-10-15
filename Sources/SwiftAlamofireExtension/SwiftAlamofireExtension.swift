import Foundation

public final class SwiftAlamofireExtensionLocalError {
    private init() {}
    
    public static let RequestBodyViolation = NSError(domain: "studio.hcmc.alamofire", code: -1)
    public static let ResponseIsNil = NSError(domain: "studio.hcmc.alamofire", code: -2)
}
