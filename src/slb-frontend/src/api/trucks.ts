import api from './client'
import type { ApiResponse, PagedResponse, Truck, Driver } from '@/types'

export const getTrucks = (page = 1, pageSize = 20) =>
  api.get<ApiResponse<PagedResponse<Truck>>>('/trucks', { params: { page, pageSize } }).then((r) => r.data)

export const createTruck = (data: Partial<Truck>) =>
  api.post<ApiResponse<Truck>>('/trucks', data).then((r) => r.data)

export const updateTruck = (id: string, data: Partial<Truck>) =>
  api.put<ApiResponse<boolean>>(`/trucks/${id}`, data).then((r) => r.data)

export const getDrivers = (page = 1, pageSize = 20) =>
  api.get<ApiResponse<PagedResponse<Driver>>>('/drivers', { params: { page, pageSize } }).then((r) => r.data)

export const createDriver = (data: Partial<Driver>) =>
  api.post<ApiResponse<Driver>>('/drivers', data).then((r) => r.data)

export const updateDriver = (id: string, data: Partial<Driver>) =>
  api.put<ApiResponse<boolean>>(`/drivers/${id}`, data).then((r) => r.data)
