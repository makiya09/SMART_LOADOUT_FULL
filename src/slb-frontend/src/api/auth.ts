import api from './client'
import type { ApiResponse, LoginRequest, LoginResponse } from '@/types'

export const login = (data: LoginRequest) =>
  api.post<ApiResponse<LoginResponse>>('/auth/login', data).then((r) => r.data)

export const getMe = () =>
  api.get<ApiResponse<{ userId: string; username: string; role: string }>>('/auth/me').then((r) => r.data)
