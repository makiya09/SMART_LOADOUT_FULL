import { useEffect, useRef } from 'react'
import * as signalR from '@microsoft/signalr'
import { useAuthStore } from '@/stores/authStore'

const HUB_URL = '/hubs/queue'

type QueueEventHandlers = {
  onTruckEnqueued?: (queueItem: unknown) => void
  onTruckCalled?: (queueId: string, bayCode: string, licensePlate: string) => void
  onTruckDocked?: (queueId: string, bayCode: string) => void
  onQueueStatusChanged?: (queueId: string, status: string) => void
  onQueuePriorityChanged?: (queueId: string, priority: number) => void
}

export function useQueueHub(handlers: QueueEventHandlers) {
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

    connection.on('TruckEnqueued', (...args) => handlersRef.current.onTruckEnqueued?.(...args))
    connection.on('TruckCalled', (...args) => handlersRef.current.onTruckCalled?.(...args as [string, string, string]))
    connection.on('TruckDocked', (...args) => handlersRef.current.onTruckDocked?.(...args as [string, string]))
    connection.on('QueueStatusChanged', (...args) => handlersRef.current.onQueueStatusChanged?.(...args as [string, string]))
    connection.on('QueuePriorityChanged', (...args) => handlersRef.current.onQueuePriorityChanged?.(...args as [string, number]))

    connection.onreconnecting(() => console.info('[QueueHub] reconnecting…'))
    connection.onreconnected(() => console.info('[QueueHub] reconnected'))

    connection.start().catch((err) => console.error('[QueueHub] connect error:', err))

    return () => { connection.stop() }
  }, [token])
}
