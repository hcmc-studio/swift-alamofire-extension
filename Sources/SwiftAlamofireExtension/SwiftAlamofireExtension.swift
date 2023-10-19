import Foundation

public final class SwiftAlamofireExtensionLocalError {
    private init() {}
    
    public final class Request {
        private init() {}
        
        public static let domain = "studio.hcmc.alamofire.request"
        public static let RequestBodyViolation = NSError(domain: domain, code: -1)
        public static let ResponseIsNil = NSError(domain: domain, code: -2)
    }
    
    public final class ContinuousFetchContext {
        private init() {}
        
        public static let domain = "studio.hcmc.alamofire.continuousfetchcontext"
        public static let AlreadyFetching           = NSError(domain: domain, code: -1)
        public static let NoMoreContent             = NSError(domain: domain, code: -2)
        public static let IntevalNotElapsed         = NSError(domain: domain, code: -3)
        public static let WillFetchReturnedFalse    = NSError(domain: domain, code: -4)
    }
}
