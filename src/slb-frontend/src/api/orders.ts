import api from './client'
import type { ApiResponse, PagedResponse, OrderList, OrderDetail } from '@/types'

export const getOrders = (page = 1, pageSize = 20, status?: string) =>
  api.get<ApiResponse<PagedResponse<OrderList>>>('/orders', { params: { page, pageSize, status } }).then((r) => r.data)

export const getOrderById = (id: string) =>
  api.get<ApiResponse<OrderDetail>>(`/orders/${id}`).then((r) => r.data)

export const createOrder = (data: unknown) =>
  api.post<ApiResponse<OrderDetail>>('/orders', data).then((r) => r.data)

export const updateOrderStatus = (id: string, data: { status: string; remark?: string }) =>
  api.put<ApiResponse<boolean>>(`/orders/${id}/status`, data).then((r) => r.data)

export const cancelOrder = (id: string) =>
  api.delete<ApiResponse<boolean>>(`/orders/${id}`).then((r) => r.data)
