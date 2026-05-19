import api from './client'
import type { ApiResponse, PerformanceDashboard, LossYieldDashboard, BayPerformanceDashboard, TurnaroundDashboard } from '@/types'

export const getPerformance = (from?: string, to?: string, shift?: string) =>
  api.get<ApiResponse<PerformanceDashboard>>('/analytics/performance', { params: { from, to, shift } }).then((r) => r.data)

export const getLossYield = (from?: string, to?: string) =>
  api.get<ApiResponse<LossYieldDashboard>>('/analytics/loss-yield', { params: { from, to } }).then((r) => r.data)

export const getBayPerformance = (from?: string, to?: string) =>
  api.get<ApiResponse<BayPerformanceDashboard>>('/analytics/bay', { params: { from, to } }).then((r) => r.data)

export const getTurnaround = (from?: string, to?: string) =>
  api.get<ApiResponse<TurnaroundDashboard>>('/analytics/turnaround', { params: { from, to } }).then((r) => r.data)

export const getAnalyticsConfig = () =>
  api.get<ApiResponse<unknown[]>>('/analytics/config').then((r) => r.data)
