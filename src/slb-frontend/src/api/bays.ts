import api from './client'
import type { ApiResponse, BayStatus2 } from '@/types'

export const getBays = () =>
  api.get<ApiResponse<BayStatus2[]>>('/bays').then((r) => r.data)

export const getBayById = (id: string) =>
  api.get<ApiResponse<BayStatus2>>(`/bays/${id}`).then((r) => r.data)

export const callTruck = (bayId: string, queueId: string) =>
  api.post<ApiResponse<boolean>>(`/bays/${bayId}/call`, { queueId }).then((r) => r.data)

export const confirmDock = (bayId: string, queueId: string) =>
  api.post<ApiResponse<boolean>>(`/bays/${bayId}/dock`, { queueId }).then((r) => r.data)

export const startLoading = (bayId: string) =>
  api.post<ApiResponse<boolean>>(`/bays/${bayId}/load/start`).then((r) => r.data)

export const pauseLoading = (bayId: string) =>
  api.post<ApiResponse<boolean>>(`/bays/${bayId}/load/pause`).then((r) => r.data)

export const emergencyStop = (bayId: string, reason: string) =>
  api.post<ApiResponse<boolean>>(`/bays/${bayId}/load/stop`, { reason }).then((r) => r.data)

export const completeLoading = (bayId: string) =>
  api.post<ApiResponse<boolean>>(`/bays/${bayId}/load/complete`).then((r) => r.data)

export const updateProgress = (bayId: string, actualWeight: number) =>
  api.post<ApiResponse<boolean>>(`/bays/${bayId}/load/progress`, { actualWeight }).then((r) => r.data)

export const resetBay = (bayId: string) =>
  api.post<ApiResponse<boolean>>(`/bays/${bayId}/reset`).then((r) => r.data)
