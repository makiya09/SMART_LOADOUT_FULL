import { useEffect, useRef } from 'react'
import * as signalR from '@microsoft/signalr'
import { useAuthStore } from '@/stores/authStore'

const HUB_URL = '/hubs/inventory'

type InventoryEventHandlers = {
  onStockUpdated?: (productId: string, productCode: string, currentStock: number, availableStock: number, status: string) => void
  onLowStockAlert?: (productId: string, productCode: string, currentStock: number, minStock: number) => void
}

export function useInventoryHub(handlers: InventoryEventHandlers) {
  const token = useAuthStore((s) => s.token)
  const handlersRef = useRef(handlers)
  handlersRef.current = handlers

  useEffect(() => {
    if (!token) return

    const connection = new signalR.HubConnectionBuilder()
      .withUrl(HUB_URL, { accessTokenFactory: () => token })
      .withAutomaticReconnect([0, 2000, 5000, 10000, 30000])
      .configureLogging(signalR.LogLevel.Warning)
      .build()

    connection.on('StockUpdated', (...args) =>
      handlersRef.current.onStockUpdated?.(...args as [string, string, number, number, string]))
    connection.on('LowStockAlert', (...args) =>
      handlersRef.current.onLowStockAlert?.(...args as [string, string, number, number]))

    connection.onreconnecting(() => console.info('[InventoryHub] reconnecting…'))
    connection.onreconnected(() => console.info('[InventoryHub] reconnected'))

    connection.start().catch((err) => console.error('[InventoryHub] connect error:', err))

    return () => { connection.stop() }
  }, [token])
}
