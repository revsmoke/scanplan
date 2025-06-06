import Foundation
import RoomPlan
import simd

/// Advanced volume and area calculator for irregular room shapes
class VolumeCalculator {
    
    /// Calculate precise floor area for irregular shapes
    func calculateFloorArea(_ floors: [CapturedRoom.Floor]) -> Float {
        print("📐 Calculating floor area")
        
        guard !floors.isEmpty else { return 0.0 }
        
        var totalArea: Float = 0.0
        for floor in floors {
            let dimensions = floor.dimensions
            totalArea += dimensions.x * dimensions.z
        }
        
        return totalArea
    }
    
    /// Calculate room volume with ceiling height variations
    func calculateRoomVolume(_ room: CapturedRoom) -> Float {
        print("📊 Calculating room volume")
        
        let floorArea = calculateFloorArea(room.floors)
        let ceilingHeight = calculateAverageCeilingHeight(room)
        
        return floorArea * ceilingHeight
    }
    
    /// Calculate average ceiling height
    func calculateAverageCeilingHeight(_ room: CapturedRoom) -> Float {
        print("📏 Calculating ceiling height")
        
        if !room.walls.isEmpty {
            let wallHeights = room.walls.map { $0.dimensions.y }
            return wallHeights.reduce(0, +) / Float(wallHeights.count)
        }
        
        return 2.5 // Default ceiling height
    }
}
