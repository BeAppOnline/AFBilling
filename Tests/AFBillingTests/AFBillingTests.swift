import XCTest
@testable import AFBilling
@testable import AFNetworks

final class AFBillingTests: XCTestCase {
    
    struct Dependencies {
      let iTunesDataTransferService: DataTransferService
    }
    
    
    var dependencies: Dependencies!
    
    
    lazy var iTunesDataTransferService: DataTransferService = {
        let config = ApiDataNetworkConfig(baseURL: URL(string: "https://buy.itunes.apple.com")!)
        let apiDataNetwork = DefaultNetworkService(config: config)
        return DefaultDataTransferService(with: apiDataNetwork)
    }()
    
    private func makeIAPManager() -> InAppPurchaseBillingRepository {
        return IAPManager(productIds: ["IAPConfiguration().productIdentifiers"], defaultAdjustEvent: DefaultAdjustEvent())
    }
    
    internal func makeInAppPurchaseRepository() -> IAPRepository {
        dependencies = Dependencies(iTunesDataTransferService: iTunesDataTransferService)
        return DefaultIAPRepository(manager: makeIAPManager())
    }
    
    func testExample() {
        let billingUseCase = DefaultAFBillingUseCase(inAppRepository: makeInAppPurchaseRepository())
        billingUseCase.buyProduct("test")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
