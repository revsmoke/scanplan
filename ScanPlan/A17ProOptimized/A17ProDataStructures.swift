import Foundation
import CoreML
import Metal
import simd

// MARK: - Chip Optimization Results

/// Comprehensive A17 Pro chip optimization result
struct ChipOptimizationResult: Identifiable, Codable {
    let id = UUID()
    let workload: ComputationalWorkload
    let workloadDistribution: WorkloadDistribution
    let neuralResults: NeuralEngineResult
    let gpuResults: GPUResult
    let cpuResults: CPUResult
    let thermalManagement: ThermalManagementResult
    let processingTime: TimeInterval
    let timestamp: Date
    let efficiency: Float // 0.0 - 1.0
    let powerConsumption: Float // Watts
    
    var performanceScore: Float {
        return (efficiency * 0.6) + ((1.0 - Float(processingTime)) * 0.4)
    }
    
    var isOptimal: Bool {
        return efficiency > 0.8 && powerConsumption < 12.0
    }
    
    static func empty() -> ChipOptimizationResult {
        return ChipOptimizationResult(
            workload: ComputationalWorkload.empty(),
            workloadDistribution: WorkloadDistribution.empty(),
            neuralResults: NeuralEngineResult.empty(),
            gpuResults: GPUResult.empty(),
            cpuResults: CPUResult.empty(),
            thermalManagement: ThermalManagementResult.empty(),
            processingTime: 0.0,
            timestamp: Date(),
            efficiency: 0.0,
            powerConsumption: 0.0
        )
    }
}

/// Computational workload definition
struct ComputationalWorkload: Identifiable, Codable {
    let id = UUID()
    let type: WorkloadType
    let dataSize: Float // MB
    let complexity: WorkloadComplexity
    let priority: WorkloadPriority
    let deadline: TimeInterval?
    let requirements: WorkloadRequirements
    
    static func empty() -> ComputationalWorkload {
        return ComputationalWorkload(
            type: .dataProcessing,
            dataSize: 0.0,
            complexity: .low,
            priority: .normal,
            deadline: nil,
            requirements: WorkloadRequirements()
        )
    }
}

enum WorkloadType: String, CaseIterable, Codable {
    case machineLearning = "machine_learning"
    case imageProcessing = "image_processing"
    case dataProcessing = "data_processing"
    case realTimeAnalysis = "real_time_analysis"
    
    var displayName: String {
        switch self {
        case .machineLearning: return "Machine Learning"
        case .imageProcessing: return "Image Processing"
        case .dataProcessing: return "Data Processing"
        case .realTimeAnalysis: return "Real-Time Analysis"
        }
    }
}

enum WorkloadComplexity: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case veryHigh = "very_high"
    
    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    var computeMultiplier: Float {
        switch self {
        case .low: return 1.0
        case .medium: return 2.0
        case .high: return 4.0
        case .veryHigh: return 8.0
        }
    }
}

enum WorkloadPriority: String, CaseIterable, Codable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var priorityWeight: Float {
        switch self {
        case .low: return 0.25
        case .normal: return 0.5
        case .high: return 0.75
        case .critical: return 1.0
        }
    }
}

/// Workload requirements
struct WorkloadRequirements: Codable {
    let memoryBandwidth: Float // GB/s
    let computeIntensity: ComputeIntensity
    let parallelizability: Float // 0.0 - 1.0
    let realTimeConstraints: Bool
    
    init() {
        self.memoryBandwidth = 100.0
        self.computeIntensity = .medium
        self.parallelizability = 0.5
        self.realTimeConstraints = false
    }
    
    init(memoryBandwidth: Float, computeIntensity: ComputeIntensity, parallelizability: Float, realTimeConstraints: Bool) {
        self.memoryBandwidth = memoryBandwidth
        self.computeIntensity = computeIntensity
        self.parallelizability = parallelizability
        self.realTimeConstraints = realTimeConstraints
    }
}

enum ComputeIntensity: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case veryHigh = "very_high"
    
    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - Workload Distribution

/// Workload distribution across chip components
struct WorkloadDistribution: Codable {
    let neuralTasks: [NeuralTask]
    let gpuTasks: [GPUTask]
    let cpuTasks: [CPUTask]
    let distribution: ComponentDistribution
    let balancingStrategy: BalancingStrategy
    
    static func empty() -> WorkloadDistribution {
        return WorkloadDistribution(
            neuralTasks: [],
            gpuTasks: [],
            cpuTasks: [],
            distribution: ComponentDistribution(neural: 0.0, gpu: 0.0, cpu: 0.0),
            balancingStrategy: .balanced
        )
    }
}

/// Component distribution percentages
struct ComponentDistribution: Codable {
    let neural: Float // 0.0 - 1.0
    let gpu: Float // 0.0 - 1.0
    let cpu: Float // 0.0 - 1.0
    
    var isValid: Bool {
        return abs((neural + gpu + cpu) - 1.0) < 0.01
    }
}

enum BalancingStrategy: String, CaseIterable, Codable {
    case performance = "performance"
    case efficiency = "efficiency"
    case balanced = "balanced"
    case powerSaving = "power_saving"
    
    var displayName: String {
        switch self {
        case .performance: return "Performance"
        case .efficiency: return "Efficiency"
        case .balanced: return "Balanced"
        case .powerSaving: return "Power Saving"
        }
    }
}

// MARK: - Neural Engine

/// Neural Engine optimization result
struct NeuralEngineResult: Identifiable, Codable {
    let id = UUID()
    let tasksExecuted: [NeuralTask]
    let utilization: Float // 0.0 - 1.0
    let efficiency: Float // 0.0 - 1.0
    let throughput: Float // TOPS
    let latency: TimeInterval
    let powerConsumption: Float // Watts
    let modelOptimizations: [ModelOptimization]
    
    static func empty() -> NeuralEngineResult {
        return NeuralEngineResult(
            tasksExecuted: [],
            utilization: 0.0,
            efficiency: 0.0,
            throughput: 0.0,
            latency: 0.0,
            powerConsumption: 0.0,
            modelOptimizations: []
        )
    }
}

/// Neural Engine task
struct NeuralTask: Identifiable, Codable {
    let id = UUID()
    let taskType: NeuralTaskType
    let model: MLModelInfo
    let inputSize: Int
    let outputSize: Int
    let precision: NeuralPrecision
    let priority: TaskPriority
    
    var computeRequirement: Float {
        return Float(inputSize * outputSize) * precision.computeMultiplier
    }
}

enum NeuralTaskType: String, CaseIterable, Codable {
    case inference = "inference"
    case classification = "classification"
    case objectDetection = "object_detection"
    case segmentation = "segmentation"
    case featureExtraction = "feature_extraction"
    
    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

enum NeuralPrecision: String, CaseIterable, Codable {
    case float32 = "float32"
    case float16 = "float16"
    case int8 = "int8"
    case int4 = "int4"
    
    var displayName: String {
        return rawValue.uppercased()
    }
    
    var computeMultiplier: Float {
        switch self {
        case .float32: return 4.0
        case .float16: return 2.0
        case .int8: return 1.0
        case .int4: return 0.5
        }
    }
}

enum TaskPriority: String, CaseIterable, Codable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case realTime = "real_time"
    
    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

/// ML Model information
struct MLModelInfo: Codable {
    let name: String
    let type: ModelType
    let size: Int // MB
    let complexity: ModelComplexity
    let optimizations: [ModelOptimization]
}

enum ModelType: String, CaseIterable, Codable {
    case coreML = "core_ml"
    case onnx = "onnx"
    case tensorFlow = "tensor_flow"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .coreML: return "Core ML"
        case .onnx: return "ONNX"
        case .tensorFlow: return "TensorFlow"
        case .custom: return "Custom"
        }
    }
}

enum ModelComplexity: String, CaseIterable, Codable {
    case simple = "simple"
    case moderate = "moderate"
    case complex = "complex"
    case veryComplex = "very_complex"
    
    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

enum ModelOptimization: String, CaseIterable, Codable {
    case quantization = "quantization"
    case pruning = "pruning"
    case distillation = "distillation"
    case compilation = "compilation"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - GPU Compute

/// GPU acceleration result
struct GPUResult: Identifiable, Codable {
    let id = UUID()
    let tasksExecuted: [GPUTask]
    let utilization: Float // 0.0 - 1.0
    let efficiency: Float // 0.0 - 1.0
    let throughput: Float // GFLOPS
    let memoryBandwidth: Float // GB/s
    let powerConsumption: Float // Watts
    let computePipelines: [ComputePipelineInfo]
    
    static func empty() -> GPUResult {
        return GPUResult(
            tasksExecuted: [],
            utilization: 0.0,
            efficiency: 0.0,
            throughput: 0.0,
            memoryBandwidth: 0.0,
            powerConsumption: 0.0,
            computePipelines: []
        )
    }
}

/// GPU compute task
struct GPUTask: Identifiable, Codable {
    let id = UUID()
    let taskType: GPUTaskType
    let dataSize: Int // MB
    let computeComplexity: ComputeComplexity
    let memoryPattern: MemoryAccessPattern
    let parallelism: ParallelismLevel
    
    var computeRequirement: Float {
        return Float(dataSize) * computeComplexity.multiplier * parallelism.efficiency
    }
}

enum GPUTaskType: String, CaseIterable, Codable {
    case matrixMultiplication = "matrix_multiplication"
    case convolution = "convolution"
    case imageProcessing = "image_processing"
    case pointCloudProcessing = "point_cloud_processing"
    case meshGeneration = "mesh_generation"
    
    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

enum ComputeComplexity: String, CaseIterable, Codable {
    case simple = "simple"
    case moderate = "moderate"
    case complex = "complex"
    case veryComplex = "very_complex"
    
    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    var multiplier: Float {
        switch self {
        case .simple: return 1.0
        case .moderate: return 2.0
        case .complex: return 4.0
        case .veryComplex: return 8.0
        }
    }
}

enum MemoryAccessPattern: String, CaseIterable, Codable {
    case sequential = "sequential"
    case random = "random"
    case strided = "strided"
    case coalesced = "coalesced"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var efficiency: Float {
        switch self {
        case .coalesced: return 1.0
        case .sequential: return 0.8
        case .strided: return 0.6
        case .random: return 0.4
        }
    }
}

enum ParallelismLevel: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case maximum = "maximum"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var efficiency: Float {
        switch self {
        case .low: return 0.25
        case .medium: return 0.5
        case .high: return 0.75
        case .maximum: return 1.0
        }
    }
}

/// Compute pipeline information
struct ComputePipelineInfo: Codable {
    let name: String
    let threadgroupSize: MTLSize
    let threadsPerThreadgroup: MTLSize
    let memoryUsage: Int // Bytes
    let efficiency: Float
}

// MARK: - CPU Performance

/// CPU performance result
struct CPUResult: Identifiable, Codable {
    let id = UUID()
    let tasksExecuted: [CPUTask]
    let utilization: Float // 0.0 - 1.0
    let efficiency: Float // 0.0 - 1.0
    let throughput: Float // Instructions per second
    let cacheHitRate: Float // 0.0 - 1.0
    let powerConsumption: Float // Watts
    let coreUtilization: [CoreUtilization]
    
    static func empty() -> CPUResult {
        return CPUResult(
            tasksExecuted: [],
            utilization: 0.0,
            efficiency: 0.0,
            throughput: 0.0,
            cacheHitRate: 0.0,
            powerConsumption: 0.0,
            coreUtilization: []
        )
    }
}

/// CPU task
struct CPUTask: Identifiable, Codable {
    let id = UUID()
    let taskType: CPUTaskType
    let dataSize: Int // MB
    let computeIntensity: CPUComputeIntensity
    let memoryIntensity: MemoryIntensity
    let vectorizable: Bool
    
    var computeRequirement: Float {
        let baseRequirement = Float(dataSize) * computeIntensity.multiplier
        return vectorizable ? baseRequirement * 0.5 : baseRequirement
    }
}

enum CPUTaskType: String, CaseIterable, Codable {
    case dataProcessing = "data_processing"
    case algorithmicComputation = "algorithmic_computation"
    case systemManagement = "system_management"
    case coordinationTask = "coordination_task"
    
    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

enum CPUComputeIntensity: String, CaseIterable, Codable {
    case light = "light"
    case moderate = "moderate"
    case intensive = "intensive"
    case veryIntensive = "very_intensive"
    
    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    var multiplier: Float {
        switch self {
        case .light: return 1.0
        case .moderate: return 2.0
        case .intensive: return 4.0
        case .veryIntensive: return 8.0
        }
    }
}

enum MemoryIntensity: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case veryHigh = "very_high"
    
    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

/// CPU core utilization
struct CoreUtilization: Codable {
    let coreType: CPUCoreType
    let coreIndex: Int
    let utilization: Float // 0.0 - 1.0
    let frequency: Float // GHz
    let temperature: Float // °C
}

enum CPUCoreType: String, CaseIterable, Codable {
    case performance = "performance"
    case efficiency = "efficiency"

    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Hardware Capabilities

/// A17 Pro chip model detection
enum ChipModel: String, CaseIterable, Codable {
    case a17Pro = "a17_pro"
    case a16Bionic = "a16_bionic"
    case a15Bionic = "a15_bionic"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .a17Pro: return "A17 Pro"
        case .a16Bionic: return "A16 Bionic"
        case .a15Bionic: return "A15 Bionic"
        case .unknown: return "Unknown"
        }
    }

    var neuralEngineGeneration: NeuralEngineGeneration {
        switch self {
        case .a17Pro: return .gen6
        case .a16Bionic: return .gen5
        case .a15Bionic: return .gen4
        case .unknown: return .unknown
        }
    }
}

/// Comprehensive chip capabilities
struct ChipCapabilities: Codable {
    let chipModel: ChipModel
    let neuralEngine: NeuralEngineCapabilities
    let gpu: GPUCapabilities
    let cpu: CPUCapabilities

    init() {
        self.chipModel = .unknown
        self.neuralEngine = NeuralEngineCapabilities()
        self.gpu = GPUCapabilities()
        self.cpu = CPUCapabilities()
    }

    init(chipModel: ChipModel, neuralEngine: NeuralEngineCapabilities, gpu: GPUCapabilities, cpu: CPUCapabilities) {
        self.chipModel = chipModel
        self.neuralEngine = neuralEngine
        self.gpu = gpu
        self.cpu = cpu
    }
}

/// Neural Engine capabilities
struct NeuralEngineCapabilities: Codable {
    let generation: NeuralEngineGeneration
    let coreCount: Int
    let operationsPerSecond: Int64 // Operations per second
    let memoryBandwidth: Float // GB/s
    let supportedPrecisions: [NeuralPrecision]

    init() {
        self.generation = .unknown
        self.coreCount = 16
        self.operationsPerSecond = 15_800_000_000_000 // 15.8 TOPS
        self.memoryBandwidth = 400.0
        self.supportedPrecisions = [.float16, .int8]
    }

    init(generation: NeuralEngineGeneration, coreCount: Int, operationsPerSecond: Int64, memoryBandwidth: Float, supportedPrecisions: [NeuralPrecision]) {
        self.generation = generation
        self.coreCount = coreCount
        self.operationsPerSecond = operationsPerSecond
        self.memoryBandwidth = memoryBandwidth
        self.supportedPrecisions = supportedPrecisions
    }

    var description: String {
        let tops = Float(operationsPerSecond) / 1_000_000_000_000.0
        return "\(generation.displayName) - \(coreCount) cores, \(String(format: "%.1f", tops)) TOPS"
    }
}

enum NeuralEngineGeneration: String, CaseIterable, Codable {
    case gen6 = "gen6"
    case gen5 = "gen5"
    case gen4 = "gen4"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .gen6: return "6th Generation"
        case .gen5: return "5th Generation"
        case .gen4: return "4th Generation"
        case .unknown: return "Unknown"
        }
    }
}

/// GPU capabilities
struct GPUCapabilities: Codable {
    let architecture: GPUArchitecture
    let coreCount: Int
    let computeUnits: Int
    let memoryBandwidth: Float // GB/s
    let maxComputeThreads: Int

    init() {
        self.architecture = .unknown
        self.coreCount = 5
        self.computeUnits = 20
        self.memoryBandwidth = 400.0
        self.maxComputeThreads = 1024
    }

    init(architecture: GPUArchitecture, coreCount: Int, computeUnits: Int, memoryBandwidth: Float, maxComputeThreads: Int) {
        self.architecture = architecture
        self.coreCount = coreCount
        self.computeUnits = computeUnits
        self.memoryBandwidth = memoryBandwidth
        self.maxComputeThreads = maxComputeThreads
    }

    var description: String {
        return "\(architecture.displayName) - \(coreCount) cores, \(computeUnits) compute units"
    }
}

enum GPUArchitecture: String, CaseIterable, Codable {
    case a17ProGPU = "a17_pro_gpu"
    case a16GPU = "a16_gpu"
    case a15GPU = "a15_gpu"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .a17ProGPU: return "A17 Pro GPU"
        case .a16GPU: return "A16 GPU"
        case .a15GPU: return "A15 GPU"
        case .unknown: return "Unknown GPU"
        }
    }
}

/// CPU capabilities
struct CPUCapabilities: Codable {
    let architecture: CPUArchitecture
    let performanceCores: Int
    let efficiencyCores: Int
    let maxFrequency: Float // GHz
    let cacheSize: Int // MB
    let instructionSets: [InstructionSet]

    init() {
        self.architecture = .unknown
        self.performanceCores = 2
        self.efficiencyCores = 4
        self.maxFrequency = 3.46
        self.cacheSize = 24
        self.instructionSets = [.armv8, .neon]
    }

    init(architecture: CPUArchitecture, performanceCores: Int, efficiencyCores: Int, maxFrequency: Float, cacheSize: Int, instructionSets: [InstructionSet]) {
        self.architecture = architecture
        self.performanceCores = performanceCores
        self.efficiencyCores = efficiencyCores
        self.maxFrequency = maxFrequency
        self.cacheSize = cacheSize
        self.instructionSets = instructionSets
    }

    var description: String {
        return "\(architecture.displayName) - \(performanceCores)P+\(efficiencyCores)E cores, \(maxFrequency) GHz"
    }
}

enum CPUArchitecture: String, CaseIterable, Codable {
    case a17ProCPU = "a17_pro_cpu"
    case a16CPU = "a16_cpu"
    case a15CPU = "a15_cpu"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .a17ProCPU: return "A17 Pro CPU"
        case .a16CPU: return "A16 CPU"
        case .a15CPU: return "A15 CPU"
        case .unknown: return "Unknown CPU"
        }
    }
}

enum InstructionSet: String, CaseIterable, Codable {
    case armv8 = "armv8"
    case neon = "neon"
    case sve = "sve"

    var displayName: String {
        return rawValue.uppercased()
    }
}

// MARK: - Performance Profiles

/// Performance profile for chip optimization
struct PerformanceProfile: Codable {
    let chipModel: ChipModel
    let capabilities: ChipCapabilities
    let thermalCharacteristics: ThermalCharacteristics
    let powerCharacteristics: PowerCharacteristics
    let optimizationParameters: OptimizationParameters

    init() {
        self.chipModel = .unknown
        self.capabilities = ChipCapabilities()
        self.thermalCharacteristics = ThermalCharacteristics()
        self.powerCharacteristics = PowerCharacteristics()
        self.optimizationParameters = OptimizationParameters()
    }

    init(chipModel: ChipModel, capabilities: ChipCapabilities, thermalCharacteristics: ThermalCharacteristics, powerCharacteristics: PowerCharacteristics, optimizationParameters: OptimizationParameters) {
        self.chipModel = chipModel
        self.capabilities = capabilities
        self.thermalCharacteristics = thermalCharacteristics
        self.powerCharacteristics = powerCharacteristics
        self.optimizationParameters = optimizationParameters
    }
}

/// Thermal characteristics
struct ThermalCharacteristics: Codable {
    let maxOperatingTemperature: Float // °C
    let optimalTemperature: Float // °C
    let throttlingThreshold: Float // °C
    let coolingEfficiency: Float // 0.0 - 1.0

    init() {
        self.maxOperatingTemperature = 85.0
        self.optimalTemperature = 45.0
        self.throttlingThreshold = 75.0
        self.coolingEfficiency = 0.7
    }

    init(maxOperatingTemperature: Float, optimalTemperature: Float, throttlingThreshold: Float, coolingEfficiency: Float) {
        self.maxOperatingTemperature = maxOperatingTemperature
        self.optimalTemperature = optimalTemperature
        self.throttlingThreshold = throttlingThreshold
        self.coolingEfficiency = coolingEfficiency
    }
}

/// Power characteristics
struct PowerCharacteristics: Codable {
    let maxPowerConsumption: Float // Watts
    let idlePowerConsumption: Float // Watts
    let powerEfficiency: Float // 0.0 - 1.0
    let batteryOptimization: Bool

    init() {
        self.maxPowerConsumption = 14.0
        self.idlePowerConsumption = 0.5
        self.powerEfficiency = 0.8
        self.batteryOptimization = true
    }

    init(maxPowerConsumption: Float, idlePowerConsumption: Float, powerEfficiency: Float, batteryOptimization: Bool) {
        self.maxPowerConsumption = maxPowerConsumption
        self.idlePowerConsumption = idlePowerConsumption
        self.powerEfficiency = powerEfficiency
        self.batteryOptimization = batteryOptimization
    }
}

/// Optimization parameters
struct OptimizationParameters: Codable {
    let enableDynamicFrequency: Bool
    let enableThermalThrottling: Bool
    let enablePowerGating: Bool
    let enableWorkloadBalancing: Bool
    let aggressiveOptimization: Bool

    init() {
        self.enableDynamicFrequency = true
        self.enableThermalThrottling = true
        self.enablePowerGating = true
        self.enableWorkloadBalancing = true
        self.aggressiveOptimization = false
    }

    init(enableDynamicFrequency: Bool, enableThermalThrottling: Bool, enablePowerGating: Bool, enableWorkloadBalancing: Bool, aggressiveOptimization: Bool) {
        self.enableDynamicFrequency = enableDynamicFrequency
        self.enableThermalThrottling = enableThermalThrottling
        self.enablePowerGating = enablePowerGating
        self.enableWorkloadBalancing = enableWorkloadBalancing
        self.aggressiveOptimization = aggressiveOptimization
    }
}

// MARK: - Thermal Management

/// Thermal management result
struct ThermalManagementResult: Codable {
    let currentTemperature: Float // °C
    let thermalState: ChipThermalState
    let throttlingActive: Bool
    let coolingStrategy: CoolingStrategy
    let powerReduction: Float // 0.0 - 1.0
    let performanceImpact: Float // 0.0 - 1.0

    static func empty() -> ThermalManagementResult {
        return ThermalManagementResult(
            currentTemperature: 35.0,
            thermalState: .optimal,
            throttlingActive: false,
            coolingStrategy: .passive,
            powerReduction: 0.0,
            performanceImpact: 0.0
        )
    }
}

enum ChipThermalState: String, CaseIterable, Codable {
    case optimal = "optimal"
    case normal = "normal"
    case warm = "warm"
    case hot = "hot"

    var displayName: String {
        return rawValue.capitalized
    }

    var color: String {
        switch self {
        case .optimal: return "blue"
        case .normal: return "green"
        case .warm: return "yellow"
        case .hot: return "red"
        }
    }
}

enum CoolingStrategy: String, CaseIterable, Codable {
    case passive = "passive"
    case frequencyReduction = "frequency_reduction"
    case powerGating = "power_gating"
    case workloadReduction = "workload_reduction"

    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - Performance Metrics

/// Chip processing load
enum ChipProcessingLoad: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"

    var displayName: String {
        return rawValue.capitalized
    }

    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "red"
        }
    }
}

/// Comprehensive chip metrics
struct ChipMetrics: Codable {
    let averageProcessingTime: TimeInterval
    let averageEfficiency: Float
    let averagePowerConsumption: Float
    let neuralEngineUtilization: Float
    let gpuUtilization: Float
    let cpuUtilization: Float
    let thermalState: ChipThermalState
    let totalOptimizations: Int

    init() {
        self.averageProcessingTime = 0.0
        self.averageEfficiency = 0.0
        self.averagePowerConsumption = 0.0
        self.neuralEngineUtilization = 0.0
        self.gpuUtilization = 0.0
        self.cpuUtilization = 0.0
        self.thermalState = .optimal
        self.totalOptimizations = 0
    }

    init(averageProcessingTime: TimeInterval, averageEfficiency: Float, averagePowerConsumption: Float, neuralEngineUtilization: Float, gpuUtilization: Float, cpuUtilization: Float, thermalState: ChipThermalState, totalOptimizations: Int) {
        self.averageProcessingTime = averageProcessingTime
        self.averageEfficiency = averageEfficiency
        self.averagePowerConsumption = averagePowerConsumption
        self.neuralEngineUtilization = neuralEngineUtilization
        self.gpuUtilization = gpuUtilization
        self.cpuUtilization = cpuUtilization
        self.thermalState = thermalState
        self.totalOptimizations = totalOptimizations
    }

    var performanceLevel: PerformanceLevel {
        if averageProcessingTime < 0.01 && averageEfficiency > 0.9 && averagePowerConsumption < 10.0 {
            return .excellent
        } else if averageProcessingTime < 0.02 && averageEfficiency > 0.8 && averagePowerConsumption < 12.0 {
            return .good
        } else if averageProcessingTime < 0.05 && averageEfficiency > 0.7 && averagePowerConsumption < 14.0 {
            return .acceptable
        } else {
            return .poor
        }
    }
}

/// Chip performance data
struct ChipPerformance {
    let neuralEngineUtilization: Float
    let gpuUtilization: Float
    let cpuUtilization: Float
    let thermalState: ChipThermalState
    let powerConsumption: Float
    let efficiency: Float
    let processingLoad: ChipProcessingLoad
}

/// Chip performance metric
struct ChipPerformanceMetric: Codable {
    let metricType: ChipMetricType
    let value: Float
    let timestamp: Date
}

enum ChipMetricType: String, CaseIterable, Codable {
    case processingTime = "processing_time"
    case efficiency = "efficiency"
    case powerConsumption = "power_consumption"
    case temperature = "temperature"
    case utilization = "utilization"

    var displayName: String {
        switch self {
        case .processingTime: return "Processing Time"
        case .efficiency: return "Efficiency"
        case .powerConsumption: return "Power Consumption"
        case .temperature: return "Temperature"
        case .utilization: return "Utilization"
        }
    }

    var unit: String {
        switch self {
        case .processingTime: return "ms"
        case .efficiency: return "%"
        case .powerConsumption: return "W"
        case .temperature: return "°C"
        case .utilization: return "%"
        }
    }
}

// MARK: - Workload Analysis

/// Workload analysis result
struct WorkloadAnalysis: Codable {
    let workloadType: WorkloadType
    let complexity: WorkloadComplexity
    let parallelizability: Float
    let memoryRequirements: MemoryRequirements
    let computeIntensity: ComputeIntensity
    let optimalDistribution: ComponentDistribution
}

/// Memory requirements
struct MemoryRequirements: Codable {
    let totalMemory: Float // MB
    let bandwidth: Float // GB/s
    let accessPattern: MemoryAccessPattern
    let cacheEfficiency: Float // 0.0 - 1.0

    init() {
        self.totalMemory = 100.0
        self.bandwidth = 100.0
        self.accessPattern = .sequential
        self.cacheEfficiency = 0.8
    }

    init(totalMemory: Float, bandwidth: Float, accessPattern: MemoryAccessPattern, cacheEfficiency: Float) {
        self.totalMemory = totalMemory
        self.bandwidth = bandwidth
        self.accessPattern = accessPattern
        self.cacheEfficiency = cacheEfficiency
    }
}

// MARK: - History Tracking

/// Performance frame for history tracking
struct PerformanceFrame: Codable {
    let result: ChipOptimizationResult
    let timestamp: Date

    var efficiency: Float {
        return result.efficiency
    }

    var powerConsumption: Float {
        return result.powerConsumption
    }

    var processingTime: TimeInterval {
        return result.processingTime
    }
}

/// Thermal reading for history
struct ThermalReading: Codable {
    let temperature: Float
    let thermalState: ChipThermalState
    let timestamp: Date
}

/// Workload reading for history
struct WorkloadReading: Codable {
    let workloadType: WorkloadType
    let complexity: WorkloadComplexity
    let distribution: ComponentDistribution
    let timestamp: Date
}

// MARK: - Compute Task Types

/// GPU compute task
struct GPUComputeTask: Identifiable, Codable {
    let id = UUID()
    let name: String
    let computeType: GPUComputeType
    let dataSize: Int // MB
    let complexity: ComputeComplexity
    let priority: TaskPriority
}

enum GPUComputeType: String, CaseIterable, Codable {
    case matrixOperations = "matrix_operations"
    case imageFiltering = "image_filtering"
    case pointCloudProcessing = "point_cloud_processing"
    case meshGeneration = "mesh_generation"
    case parallelCompute = "parallel_compute"

    var displayName: String {
        return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
