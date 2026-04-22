import Foundation
import IOKit.pwr_mgt

/// Holds `PreventUserIdleDisplaySleep` while active (same practical goal as `caffeinate -d`).
final class PowerAssertionHolder {
    private var assertionID: IOPMAssertionID = 0

    var isActive: Bool { assertionID != 0 }

    func setActive(_ active: Bool) {
        if active {
            guard assertionID == 0 else { return }
            var id: IOPMAssertionID = 0
            let reason = "JitterJuice display awake" as CFString
            let type = kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString
            let status = IOPMAssertionCreateWithName(type, IOPMAssertionLevel(kIOPMAssertionLevelOn), reason, &id)
            if status == kIOReturnSuccess {
                assertionID = id
            }
        } else {
            guard assertionID != 0 else { return }
            IOPMAssertionRelease(assertionID)
            assertionID = 0
        }
    }

    deinit {
        setActive(false)
    }
}
