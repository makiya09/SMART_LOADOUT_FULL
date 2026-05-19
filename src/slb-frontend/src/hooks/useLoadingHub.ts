import { useEffect, useRef } from 'react'
import * as signalR from '@microsoft/signalr'
import { useAuthStore } from '@/stores/authStore'
import { useBayStore } from '@/stores/bayStore'

const HUB_URL = '/hubs/loading'

export function useLoadingHub() {
  const token = useAuthStore((s) => s.token)
  const connectionRef = useRef<signalR.HubConnection | null>(null)

  useEffect(() => {
    if (!token) return

    const connection = new signalR.HubConnectionBuilder()
      .withUrl(HUB_URL, { accessTokenFactory: () => token })
      .withAutomaticReconnect([0, 2000, 5000, 10000, 30000])
      .configureLogging(signalR.LogLevel.Warning)
      .build()

    connection.on('BayStatusChanged', (bayCode: string, status: string) => {
      useBayStore.getState().bays.forEach((b) => {
        if (b.bayCode === bayCode)
          useBayStore.getState().updateBay(b.bayId, { status: status as never })
      })
    })

    connection.on('LoadingStarted', (bayCode: string, jobId: string, targetWeight: number) => {
      useBayStore.getState().bays.forEach((b) => {
        if (b.bayCode === bayCode && b.currentJob)
          useBayStore.getState().updateBay(b.bayId, {
            currentJob: { ...b.currentJob, jobId, targetWeight, status: 'LOADING' as never },
          })
      })
    })

    connection.on('LoadingProgress', (bayCode: string, actualWeight: number, progressPct: number) => {
      useBayStore.getState().bays.forEach((b) => {
        if (b.bayCode === bayCode && b.currentJob)
          useBayStore.getState().updateBay(b.bayId, { currentJob: { ...b.currentJob, actualWeight, progressPct } })
      })
    })

    connection.on('LoadingCompleted', (bayCode: string) => {
      useBayStore.getState().bays.forEach((b) => {
        if (b.bayCode === bayCode)
          useBayStore.getState().updateBay(b.bayId, { status: 'AVAILABLE' as never, currentQueueId: undefined, currentJob: undefined })
      })
    })

    connection.on('EmergencyStop', (bayCode: string) => {
      useBayStore.getState().bays.forEach((b) => {
        if (b.bayCode === bayCode)
          useBayStore.getState().updateBay(b.bayId, { status: 'ERROR' as never })
      })
    })

    connection.onreconnecting(() => console.info('[LoadingHub] reconnecting…'))
    connection.onreconnected(() => console.info('[LoadingHub] reconnected'))

    connectionRef.current = connection
    connection.start().catch((err) => console.error('[LoadingHub] connect error:', err))

    return () => { connection.stop() }
  }, [token])

  const joinBayGroup = async (bayCode: string) => {
    if (connectionRef.current?.state === signalR.HubConnectionState.Connected)
      await connectionRef.current.invoke('JoinBayGroup', bayCode)
  }

  const leaveBayGroup = async (bayCode: string) => {
    if (connectionRef.current?.state === signalR.HubConnectionState.Connected)
      await connectionRef.current.invoke('LeaveBayGroup', bayCode)
  }

  return { joinBayGroup, leaveBayGroup }
}
