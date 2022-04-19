//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

struct MobileProvision: Decodable {

    var entitlements: Entitlements

    private enum CodingKeys: String, CodingKey {
        case entitlements = "Entitlements"
    }

    struct Entitlements: Decodable {

        let apsEnvironment: Environment

        private enum CodingKeys: String, CodingKey {
            case apsEnvironment = "aps-environment"
        }

        enum Environment: String, Decodable {
            case development, production, disabled
        }

        init(apsEnvironment: Environment) {
            self.apsEnvironment = apsEnvironment
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let apsEnvironment: Environment = try container.decodeIfPresent(Environment.self, forKey: .apsEnvironment) ?? .disabled
            self.init(apsEnvironment: apsEnvironment)
        }
    }
}

extension MobileProvision {
    
    enum UIApplicationReleaseMode: Int {
        case  unknown,
              releaseDev,
              releaseAdHoc,
              releaseWildcard,
              releaseAppStore,
              releaseSim,
              releaseEnterprise
    }
    
    private struct PlistTags {
        static let start = "<plist"
        static let end = "</plist>"
    }
    
    static func read() throws -> MobileProvision {
        let profilePath: String = try unwrap(Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"))
        return try read(from: profilePath)
    }
    
    static func read(from profilePath: String) throws ->  MobileProvision {
        let profile = try String(contentsOfFile: profilePath, encoding: String.Encoding.isoLatin1)
        let plistString: String = try unwrap(convertPlistDataToString(profile))
        let plistData: Data = try unwrap(plistString.appending(PlistTags.end).data(using: .isoLatin1))
        let decoder = PropertyListDecoder()
        return try decoder.decode(MobileProvision.self, from: plistData)
    }
    
    private static func convertPlistDataToString(_ string: String) throws -> String {
        let scanner = Scanner(string: string)
        let startError = GuardError.custom("Not found plist tag \(PlistTags.start), in '\(string)'")
        let endError = GuardError.custom("Not found plist tag \(PlistTags.end), in '\(string)'")
        _ = try unwrap(scanner.scanUpTo(PlistTags.start, into: nil), error: startError)
        var extractedPlist: NSString?
        guard scanner.scanUpTo(PlistTags.end, into: &extractedPlist) != false else {
            throw endError
        }
        return String(try unwrap(extractedPlist))
    }
    
    static func getMobileProvision() -> NSDictionary? {
        var mobileProvision: NSDictionary?
        
        let provisioningPath = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision")
        if (provisioningPath == nil) {
            return [:];
        }
        
        var binaryString: String? = nil
            //reading
            do {
                binaryString = try String(contentsOfFile: provisioningPath!, encoding: .isoLatin1)
            }
            catch {/* error handling here */}
//        }
        
        // NSISOLatin1 keeps the binary wrapper from being parsed as unicode and dropped as invalid
        if (binaryString == nil) {
            return nil;
        }
        
        if #available(iOS 13.0, *) {
            let scanner = Scanner(string: binaryString!)
            var ok = scanner.scanUpToString("<plist")
            if ((ok == nil)) { print("unable to find beginning of plist"); return nil; }
            ok = scanner.scanUpToString("</plist>")
            if ((ok == nil)) { print("unable to find end of plist"); return nil; }
            let plistString = String.localizedStringWithFormat("%@</plist>", ok!)
            // juggle latin1 back to utf-8!
            let plistdata_latin1 = plistString.data(using: .isoLatin1)
            //        plistString = [NSString stringWithUTF8String:[plistdata_latin1 bytes]];
            //        NSData *plistdata2_latin1 = [plistString dataUsingEncoding:NSISOLatin1StringEncoding];
            mobileProvision = try! PropertyListSerialization.propertyList(from:plistdata_latin1!, format: nil) as! NSDictionary
            
            if (mobileProvision == nil) {
                return nil;
            }
        }
        else {
            return nil
        }
        return mobileProvision;
    }
    
    static func releaseMode() -> UIApplicationReleaseMode {
        var entitlements: NSDictionary
        let mobileProvision = getMobileProvision()
        
        guard mobileProvision != nil else { return .unknown }
        
        entitlements = mobileProvision!.object(forKey: "Entitlements") as! NSDictionary
        
        if mobileProvision!.count == 0 {
#if TARGET_IPHONE_SIMULATOR
            return .releaseSim;
#else
            return .releaseAppStore;
#endif
        }
        else if mobileProvision!.object(forKey: "ProvisionsAllDevices") != nil {
            return .releaseEnterprise;
        }
        else if "development".isEqual(entitlements["aps-environment"]) {
            return .releaseDev;
        }
        else {
            // app store contains no UDIDs (if the file exists at all?)
            return .releaseAppStore;
        }
    }
}
