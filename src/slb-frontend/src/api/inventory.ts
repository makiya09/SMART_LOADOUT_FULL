import api from './client'
import type { ApiResponse, PagedResponse, ProductStock } from '@/types'

export const getInventory = () =>
  api.get<ApiResponse<ProductStock[]>>('/inventory').then((r) => r.data)

export const getProductStock = (id: string) =>
  api.get<ApiResponse<ProductStock>>(`/inventory/${id}`).then((r) => r.data)

export const getInventoryHistory = (page = 1, pageSize = 20) =>
  api.get<ApiResponse<PagedResponse<unknown>>>('/inventory/history', { params: { page, pageSize } }).then((r) => r.data)

export const adjustStock = (data: { productId: string; siloId: string; qty: number; changeType: string; remark?: string }) =>
  api.post<ApiResponse<boolean>>('/inventory/adjust', data).then((r) => r.data)
