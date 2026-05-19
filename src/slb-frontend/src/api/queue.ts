import api from './client'
import type { ApiResponse, QueueItem } from '@/types'

export const getQueueBoard = () =>
  api.get<ApiResponse<QueueItem[]>>('/queue').then((r) => r.data)

export const enqueue = (data: { orderId: string; truckId: string; driverId: string; priority: number; remark?: string }) =>
  api.post<ApiResponse<QueueItem>>('/queue/enqueue', data).then((r) => r.data)

export const updateQueuePriority = (id: string, priority: number) =>
  api.put<ApiResponse<boolean>>(`/queue/${id}/priority`, { priority }).then((r) => r.data)

export const cancelQueue = (id: string) =>
  api.delete<ApiResponse<boolean>>(`/queue/${id}`).then((r) => r.data)
