// ─── Common ───────────────────────────────────────────────────────────────────
export interface ApiResponse<T> {
  success: boolean
  message?: string
  data?: T
  errors?: string[]
}

export interface PagedResponse<T> {
  items: T[]
  totalCount: number
  page: number
  pageSize: number
  totalPages: number
}

// ─── Auth ─────────────────────────────────────────────────────────────────────
export interface LoginRequest { username: string; password: string }
export interface LoginResponse {
  token: string; username: string; fullName: string; role: string; expiresAt: string
}

// ─── Inventory ────────────────────────────────────────────────────────────────
export type StockStatus = 'NORMAL' | 'LOW' | 'CRITICAL' | 'EMPTY'
export interface SiloStock {
  siloId: string; siloCode: string; siloName: string
  capacity: number; currentStock: number; utilizationPct: number
}
export interface ProductStock {
  productId: string; productCode: string; productName: string; unit: string
  currentStock: number; reservedStock: number; availableStock: number
  minStock: number; criticalStock: number; stockStatus: StockStatus
  silos: SiloStock[]
}

// ─── Order ────────────────────────────────────────────────────────────────────
export type OrderStatus = 'DRAFT' | 'CONFIRMED' | 'QUEUED' | 'LOADING' | 'COMPLETED' | 'CANCELLED'
export interface OrderItem {
  itemId: string; productId: string; productCode: string; productName: string
  requestedQty: number; actualQty?: number; unit: string
}
export interface OrderList {
  orderId: string; orderCode: string; customerName: string
  orderDate: string; requiredDate: string; status: OrderStatus
  totalWeight: number; itemCount: number; createdAt: string
}
export interface OrderDetail extends OrderList {
  customerId: string; remark?: string; items: OrderItem[]
}

// ─── Queue ────────────────────────────────────────────────────────────────────
export type QueueStatus = 'WAITING' | 'CALLED' | 'DOCKED' | 'LOADING' | 'DONE' | 'CANCELLED'
export interface QueueItem {
  queueId: string; orderId: string; orderCode: string; customerName: string
  truckId: string; licensePlate: string; truckType: string
  driverId: string; driverName: string; priority: number
  status: QueueStatus; enqueuedAt: string; calledAt?: string
  dockedAt?: string; completedAt?: string; remark?: string
}

// ─── Truck ────────────────────────────────────────────────────────────────────
export type TruckType = 'TRAILER' | 'TANKER' | 'TIPPER' | 'SILO'
export interface Truck {
  truckId: string; licensePlate: string; truckType: TruckType
  maxCapacity: number; companyName?: string; isActive: boolean; createdAt: string
}
export interface Driver {
  driverId: string; fullName: string; licenseNo: string
  licenseExpiry: string; phone?: string; isActive: boolean; createdAt: string
}

// ─── Bay & Loading ────────────────────────────────────────────────────────────
export type BayStatus = 'AVAILABLE' | 'CALLING' | 'DOCKED' | 'LOADING' | 'CHECKING' | 'ERROR' | 'MAINTENANCE'
export type JobStatus = 'PENDING' | 'RUNNING' | 'PAUSED' | 'COMPLETED' | 'FAILED' | 'CANCELLED'
export interface LoadingJobSummary {
  jobId: string; jobCode: string; licensePlate: string; driverName: string
  productName: string; targetWeight: number; actualWeight: number
  progressPct: number; status: JobStatus; startedAt?: string
}
export interface BayStatus2 {
  bayId: string; bayCode: string; bayName: string; bayType: string
  maxCapacity: number; status: BayStatus; currentQueueId?: string
  currentJob?: LoadingJobSummary
}

// ─── QR ───────────────────────────────────────────────────────────────────────
export interface QrToken {
  tokenId: string; jobId: string; jobCode: string
  tokenType: string; qrPayload: string; expiresAt: string; isUsed: boolean
}
export interface QrValidationResult {
  isValid: boolean; message?: string; jobId?: string; jobCode?: string
  licensePlate?: string; driverName?: string; productName?: string
  targetWeight?: number; bayCode?: string
}

// ─── Checklist ───────────────────────────────────────────────────────────────
export interface ChecklistItem {
  itemId: string; itemName: string; itemType: string
  isRequired: boolean; isChecked: boolean
  checkedAt?: string; checkedBy?: string; remark?: string
}
export interface Checklist {
  checklistId: string; jobId: string; jobCode: string
  licensePlate: string; driverName: string; productName: string
  targetWeight: number; actualWeight?: number; status: string
  items: ChecklistItem[]
}

// ─── Hardware ─────────────────────────────────────────────────────────────────
export type DeviceType = 'QR_SCANNER' | 'RADAR' | 'LOADING_PANEL' | 'SCALE' | 'MONITOR'
export type DeviceStatus = 'ONLINE' | 'OFFLINE' | 'ERROR' | 'MAINTENANCE'
export interface HardwareDevice {
  deviceId: string; deviceCode: string; deviceName: string
  deviceType: DeviceType; protocol: string; ipAddress: string; port: number
  status: DeviceStatus; lastPingAt?: string; bayCode?: string; config?: unknown
}
export interface HardwareEvent {
  eventId: number; deviceCode: string; deviceType: string
  eventType: string; payload?: string; bayCode?: string; eventTime: string
}

// ─── Analytics ───────────────────────────────────────────────────────────────
export interface PerformanceKpi {
  totalJobs: number; completedJobs: number; cancelledJobs: number; failedJobs: number
  completionRatePct: number; overallYieldPct: number
  totalLossKg: number; totalOverKg: number; totalActualTon: number
  avgAccuracyPct: number; avgLoadingMin: number; avgThroughput: number | null
}
export interface DailyTrendItem {
  date: string; totalJobs: number; completedJobs: number
  totalActualTon: number; yieldPct: number; accuracyPct: number
  throughputTonPerHour: number | null; avgLoadingMin: number
}
export interface BaySummaryItem {
  bayCode: string; bayName: string; totalJobs: number; completedJobs: number
  totalActualTon: number; avgLoadingMin: number; avgYieldPct: number
  avgThroughput: number | null; avgUtilizationPct: number
}
export interface ShiftSummaryItem {
  shiftName: string; totalJobs: number; completedJobs: number
  totalActualTon: number; avgYieldPct: number; avgLoadingMin: number
}
export interface PerformanceDashboard {
  kpi: PerformanceKpi
  dailyTrend: DailyTrendItem[]
  baySummary: BaySummaryItem[]
  shiftSummary: ShiftSummaryItem[]
}

export interface LossYieldKpi {
  totalJobs: number; totalTargetKg: number; totalActualKg: number
  overallYieldPct: number; totalLossKg: number; totalOverKg: number
  avgYieldPct: number; minYieldPct: number; maxYieldPct: number; avgYieldStdDev: number
}
export interface DailyLossItem {
  date: string; dailyYieldPct: number; totalLossKg: number; totalOverKg: number; totalJobs: number
}
export interface ProductLossItem {
  productCode: string; productName: string; totalJobs: number
  totalLossKg: number; avgYieldPct: number; yieldStdDev: number
}
export interface LossJobDetail {
  jobId: string; jobCode: string; workDate: string; bayName: string
  licensePlate: string; driverName: string; productName: string
  targetWeight: number; actualWeight: number; lossKg: number; overKg: number
  yieldPct: number; loadingDurationMin: number
}
export interface LossYieldDashboard {
  kpi: LossYieldKpi
  dailyTrend: DailyLossItem[]
  productLoss: ProductLossItem[]
  jobDetails: LossJobDetail[]
}

export interface BaySummaryExt {
  bayCode: string; bayName: string; totalJobs: number; completedJobs: number
  totalActualTon: number; totalLoadingMin: number; avgLoadingMin: number
  avgYieldPct: number; avgThroughput: number | null; avgUtilizationPct: number
}
export interface BayPerformanceDashboard {
  baySummary: BaySummaryExt[]
  dailyData: unknown[]
  hourlyData: unknown[]
}

export interface TurnaroundKpi {
  totalJobs: number; avgTurnaroundMin: number
  minTurnaroundMin: number; maxTurnaroundMin: number
  avgQueueWaitMin: number; avgDockingMin: number
  avgLoadingMin: number; avgChecklistMin: number
}
export interface TurnaroundJobItem {
  jobId: string; jobCode: string; workDate: string
  licensePlate: string; transportCompany: string | null
  driverName: string; bayName: string
  queueWaitMin: number; dockingMin: number; loadingMin: number
  checklistMin: number; turnaroundMin: number; yieldPct: number
}
export interface TurnaroundDailyItem {
  date: string; avgTurnaroundMin: number; avgQueueWaitMin: number; avgLoadingMin: number; jobCount: number
}
export interface TurnaroundDashboard {
  kpi: TurnaroundKpi
  dailyTrend: TurnaroundDailyItem[]
  jobDetails: TurnaroundJobItem[]
}
