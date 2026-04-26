import Foundation
import SwiftData

enum SeedData {
    static let quickFaults: [QuickFault] = [
        .init(label: "Won't start", symbol: "bolt.slash.fill", prompt: "Machine won't start. No response when pressing the start button."),
        .init(label: "E-stop tripped", symbol: "exclamationmark.octagon.fill", prompt: "E-stop is tripped and won't reset. Safety circuit not making up."),
        .init(label: "Sensor fault", symbol: "sensor.fill", prompt: "Photoeye sensor not detecting product. PLC input light is off."),
        .init(label: "VFD fault", symbol: "waveform.path.ecg", prompt: "VFD showing a fault code. Drive will not run motor."),
        .init(label: "Air pressure low", symbol: "wind", prompt: "Low air pressure alarm. Machine will not cycle."),
        .init(label: "Conveyor jam", symbol: "exclamationmark.triangle.fill", prompt: "Product jammed on conveyor. Belt not moving."),
        .init(label: "Overheating", symbol: "thermometer.high", prompt: "Motor running hot, smells like burnt insulation."),
        .init(label: "After sanitation", symbol: "drop.degreesign.fill", prompt: "Equipment will not start after sanitation. Possibly loose wire or disconnected airline.")
    ]

    static func equipment() -> [Equipment] {
        [
            Equipment(
                id: "EQ-101",
                name: "Infeed Conveyor",
                kind: .conveyor,
                line: "Line 1 — Infeed",
                manufacturer: "Hytrol",
                model: "EZLogic ABEZ",
                status: .running,
                lastServiced: daysAgo(12),
                commonFailures: ["Belt tracking", "Photoeye misalignment", "End-of-line disconnect off", "Drive motor overload"],
                notes: "Sanitation crew sometimes leaves disconnect off."
            ),
            Equipment(
                id: "EQ-204",
                name: "Filler #2",
                kind: .filler,
                line: "Line 2 — Fill",
                manufacturer: "Krones",
                model: "Modulfill HRS",
                status: .down,
                lastServiced: daysAgo(3),
                commonFailures: ["Fill valve sticking", "Bottle jam at infeed star", "Servo fault on lift cylinders"],
                notes: "VFD on main drive prone to overcurrent after CIP."
            ),
            Equipment(
                id: "EQ-305",
                name: "Capper",
                kind: .capper,
                line: "Line 2 — Cap",
                manufacturer: "Arol",
                model: "Equatorque ET",
                status: .running,
                lastServiced: daysAgo(28),
                commonFailures: ["Cap chute jam", "Torque drift", "Cap missing sensor"],
                notes: ""
            ),
            Equipment(
                id: "EQ-407",
                name: "Labeler",
                kind: .labeler,
                line: "Line 2 — Label",
                manufacturer: "P.E. Labellers",
                model: "Master S",
                status: .maintenance,
                lastServiced: daysAgo(1),
                commonFailures: ["Label web break", "Glue temperature low", "Registration mark drift"],
                notes: ""
            ),
            Equipment(
                id: "EQ-512",
                name: "Case Packer",
                kind: .packer,
                line: "Line 3 — Pack",
                manufacturer: "Douglas",
                model: "Axiom",
                status: .running,
                lastServiced: daysAgo(45),
                commonFailures: ["Vacuum cup wear", "Carton infeed jam", "Hot melt clogged"],
                notes: ""
            ),
            Equipment(
                id: "EQ-620",
                name: "Palletizer",
                kind: .palletizer,
                line: "Line 3 — Palletize",
                manufacturer: "Columbia",
                model: "FL-3000",
                status: .running,
                lastServiced: daysAgo(60),
                commonFailures: ["Layer sweep timing", "Pallet dispenser jam", "Light curtain interrupt"],
                notes: ""
            ),
            Equipment(
                id: "EQ-715",
                name: "Mix Tank A",
                kind: .mixer,
                line: "Utilities",
                manufacturer: "APV",
                model: "Cavitator",
                status: .running,
                lastServiced: daysAgo(20),
                commonFailures: ["Agitator seal leak", "Level sensor drift", "VFD ground fault"],
                notes: ""
            ),
            Equipment(
                id: "EQ-808",
                name: "Shrink Wrapper",
                kind: .shrinkWrap,
                line: "Line 3 — EOL",
                manufacturer: "Lantech",
                model: "Q-300",
                status: .running,
                lastServiced: daysAgo(7),
                commonFailures: ["Film roll out", "Heat element failure", "Photoeye dirty"],
                notes: ""
            )
        ]
    }

    private static func daysAgo(_ d: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -d, to: .now) ?? .now
    }
}

struct QuickFault: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let symbol: String
    let prompt: String
}
